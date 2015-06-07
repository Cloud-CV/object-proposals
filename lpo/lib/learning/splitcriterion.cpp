/*
    Copyright (c) 2015, Philipp Krähenbühl
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
        * Neither the name of the Stanford University nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY Philipp Krähenbühl ''AS IS'' AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL Philipp Krähenbühl BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include "util/algorithm.h"
#include "util/win_util.h"
#include "util/threading.h"
#include "splitcriterion.h"
#include <random>
#include <stdexcept>
#include <iostream>
#include <random>
#include <Eigen/SVD>
#include <Eigen/Eigenvalues>

int SplitCriterion::repLabel() const {
	return -1;
}
class LabeledSplit: public SplitCriterion {
protected:
	VectorXi lbl_;
	VectorXf weight_;
	virtual float score( const ArrayXf & p ) const = 0;
public:
	LabeledSplit() {
	}
	LabeledSplit( const RMatrixXf & lbl, const VectorXf & weight ): weight_(weight) {
		if( lbl.cols()!= 1 )
			throw std::invalid_argument( "Only 1d labels supported!" );
		lbl_ = lbl.cast<int>();
	}
	virtual float gain( const VectorXb& is_left ) const {
		const int N = lbl_.maxCoeff()+1;
		ArrayXf wl = 1e-20*ArrayXf::Ones(N), wr = 1e-20*ArrayXf::Ones(N);
		for( int i=0; i<(int)lbl_.size(); i++ )
			if( is_left[i] )
				wl[lbl_[i]] += weight_[i];
			else
				wr[lbl_[i]] += weight_[i];
		const float l = wl.sum(), r = wr.sum();
		const float sl = score(wl/l), sr = score(wr/r);
		printf("%d  %d\n", (int)l, (int)r );
		return score( (wl+wr)/(l+r) ) - (sl*l/(l+r) + sr*r/(l+r));
	}
	virtual float bestThreshold( const VectorXf & f, float * gain ) const {
		const int N = lbl_.maxCoeff()+1;
		const float EPS=1e-6;
		// Create the feature/label pairs
		std::vector< std::pair<float,int> > elements( f.size() );
		for( int i=0; i<f.size(); i++ )
			elements[i] = std::make_pair( f[i], i );
		std::sort(elements.begin(), elements.end() );

		// And compute the probabilities and cirterion
		ArrayXf wl = 1e-20*ArrayXf::Ones(N), wr = 1e-20*ArrayXf::Ones(N);
		for( int i=0; i<lbl_.size(); i++ )
			wr[ lbl_[i] ] += weight_[i];

		// Initialize the thresholds
		float best_gain = 0, tbest = (elements.front().first+elements.back().first)/2, last_t = elements.front().first;
		const float tot_s = score( wr/wr.sum() );
		// Find the best threshold
		for( auto i: elements ) {
			const float t = i.first;
			const int j = i.second;
			// If there is a threshold
			if( t - last_t > EPS ) {
				// Compute the score
				const float l = wl.sum(), r = wr.sum();
				const float sl = score(wl/l), sr = score(wr/r);
				const float g = tot_s - ( sl*l/(l+r) + sr*r/(l+r) );
				if( g > best_gain ) {
					best_gain = g;
					tbest = (last_t+t)/2.;
				}
			}
			// Update the probabilities
			wl[ lbl_[j] ] += weight_[j];
			wr[ lbl_[j] ] -= weight_[j];
			last_t = t;
		}
		if( gain )
			*gain = best_gain;
		return tbest;
	}
	virtual bool is_pure( ) const {
		for( int i=1; i<lbl_.size(); i++ )
			if( lbl_[0] != lbl_[i] )
				return false;
		return true;
	}
	virtual int repLabel() const {
		// Count the label occurence
		const int n_lbl = lbl_.maxCoeff()+1;
		VectorXi lbl_cnt = VectorXi::Zero( n_lbl );
		for( int i=0; i<lbl_.size(); i++ )
			lbl_cnt[lbl_[i]]++;
		// And return the maximum
		int rep_lbl = 0;
		for( int i=0; i<lbl_.size(); i++ )
			if( lbl_cnt[lbl_[rep_lbl]] < lbl_cnt[lbl_[i]] )
				rep_lbl = i;
		return rep_lbl;
	}
};
class GiniSplit: public LabeledSplit {
public:
	template<typename ...ARGS> GiniSplit(ARGS... args) :LabeledSplit(args...) {}
	virtual std::shared_ptr<SplitCriterion> create( const RMatrixXf & lbl, const VectorXf & weight ) const {
		return std::make_shared<GiniSplit>( lbl, weight );
	}
	virtual float score( const ArrayXf & p ) const {
		return (p*(1-p)).sum();
	}
};
class EntropySplit: public LabeledSplit {
public:
	template<typename ...ARGS> EntropySplit(ARGS... args) :LabeledSplit(args...) {}
	virtual std::shared_ptr<SplitCriterion> create( const RMatrixXf & lbl, const VectorXf & weight ) const {
		return std::make_shared<EntropySplit>( lbl, weight );
	}
	virtual float score( const ArrayXf & p ) const {
		return -(p*(p+1e-20).log()).sum();
	}
};
RMatrixXf pairwiseDistance( const RMatrixXf & X, int N ) {
	static std::mt19937 gen;
	// Do a random pairwise projection
	const int M = X.cols();
	RMatrixXf r( X.rows(), N );
	std::vector<int> o1(N), o2(N);
	for( int i=0; i<N; i++ ) {
		int r = gen()%((M-1)*M/2);
		o1[i] = int(sqrt(0.25+2*r)-0.5 + 0.1/M/*for numeric stability*/);
		o2[i] = r - (o1[i]+1)*o1[i]/2;
	}
	for( int i=0; i<X.rows(); i++ )
		for( int j=0; j<N; j++ )
			r(i,j) = ((X(i,o1[j]) == X(i,o2[j])));
	return r;
}
VectorXf project1D( const RMatrixXf & Y, int * rep_label=NULL ) {
// 	const int MAX_SAMPLE = 20000;
	const bool fast = true, very_fast = true;
	// Remove the DC (Y : N x M)
	RMatrixXf dY = Y.rowwise() - Y.colwise().mean();
// 	RMatrixXf sY = dY;
// 	if( 0 < MAX_SAMPLE && MAX_SAMPLE < dY.rows() ) {
// 		VectorXi samples = randomChoose( dY.rows(), MAX_SAMPLE );
// 		std::sort( samples.data(), samples.data()+samples.size() );
// 		sY = RMatrixXf( samples.size(), dY.cols() );
// 		for( int i=0; i<samples.size(); i++ )
// 			sY.row(i) = dY.row( samples[i] );
// 	}

	// ... and use (pc > 0)
	VectorXf lbl = VectorXf::Zero( Y.rows() );

	// Find the largest PC of (dY.T * dY) and project onto it
	if( very_fast ) {
		// Find the largest PC using poweriterations
		VectorXf U = VectorXf::Random( dY.cols() );
		U = U.array() / U.norm()+std::numeric_limits<float>::min();
		for( int it=0; it<20; it++ ) {
			// Normalize
			VectorXf s = dY.transpose()*(dY*U);
			s.array() /= s.norm()+std::numeric_limits<float>::min();
			if ( (U-s).norm() < 1e-6 )
				break;
			U = s;
		}
		// Project onto the PC
		lbl = dY*U;
	} else if(fast) {
		// Compute the eigen values of the covariance (and project onto the largest eigenvector)
		MatrixXf cov = dY.transpose()*dY;
		SelfAdjointEigenSolver<MatrixXf> eigensolver(0.5*(cov+cov.transpose()));
		MatrixXf ev = eigensolver.eigenvectors();
		lbl = dY * ev.col( ev.cols()-1 );
	} else {
		// Use the SVD
		JacobiSVD<RMatrixXf> svd = dY.jacobiSvd(ComputeThinU | ComputeThinV );
		// Project onto the largest PC
		lbl = svd.matrixU().col(0) * svd.singularValues()[0];
	}
	// Find the representative label
	if( rep_label )
		dY.array().square().rowwise().sum().minCoeff( rep_label );

	return (lbl.array() < 0).cast<float>();
}

template<typename Split> class Structured: public Split {
protected:
	int rep_label_;
	int n_struc_samples_;
public:
	Structured( int n_struc_samples = 256 ):n_struc_samples_(n_struc_samples) {}
	Structured( const RMatrixXf & lbl, const VectorXf & weight, int n_struc_samples ): Split( project1D(pairwiseDistance(lbl,n_struc_samples),&rep_label_), weight ) {
	}
	virtual std::shared_ptr< SplitCriterion > create( const RMatrixXf & lbl, const VectorXf & weight ) const {
		return std::make_shared< Structured<Split> >( lbl, weight, n_struc_samples_ );
	}
	virtual int repLabel() const {
		return rep_label_;
	}
};
std::shared_ptr<SplitCriterion> entropySplit() {
	return std::make_shared<EntropySplit>();
}
std::shared_ptr<SplitCriterion> giniSplit() {
	return std::make_shared<GiniSplit>();
}
std::shared_ptr<SplitCriterion> structEntropySplit( int n_struc_samples ) {
	return std::make_shared< Structured<EntropySplit> >( n_struc_samples );
}
std::shared_ptr<SplitCriterion> structGiniSplit( int n_struc_samples ) {
	return std::make_shared< Structured<GiniSplit> >( n_struc_samples );
}
