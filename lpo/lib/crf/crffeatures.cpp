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
#include "crffeatures.h"
#include "imgproc/color.h"
#include "segmentation/segmentation.h"
#include "util/util.h"
#include "util/geodesics.h"
#include <iostream>

const unsigned int ALL_STATIC_FEATURES = (1<<10)-1;
const unsigned int ALL_SEED_FEATURES = (1<<20)-(1<<10);


int unaryDim( unsigned int which ) {
	int d = 0;
	if( which & CONSTANT ) d += 1;
	if( which & POSITION ) d += 5;
	if( which & COLOR )    d += 3;
	if( which & BG_COLOR ) d += 3;
	if( which & COLOR_DF ) d += 3;
	if( which & COLOR_SQ ) d += 3;
	if( which & GEO_BND )  d += 4;
	
	if( which & SEED_INDICATOR) d += 1;
	if( which & GEO_SEED      ) d += 4;
	if( which & COLOR_SEED    ) d += 3;
	if( which & COLOR_SEED_SQ ) d += 3;
	if( which & COLOR_SEED_DF ) d += 3;
	return d;
}

StaticBinaryCRFFeatures::StaticBinaryCRFFeatures( const RMatrixXf & unary, const Edges & graph, const RMatrixXf & pairwise, int which ):graph_(graph),unary_(unary),pairwise_(pairwise),which_(which) {
	
}
StaticBinaryCRFFeatures::StaticBinaryCRFFeatures( const ImageOverSegmentation & ios, int which ):graph_(ios.edges()),which_(which) {
	makeUnary( ios );
	makePairwise( ios );
}
const RMatrixXf projectMean( const float * V, const short * S, int N, int D, int Ns=-1 ) {
	if( Ns < 0 ) {
		for( int i=0; i<N; i++ )
			Ns = std::max( Ns, (int)S[i]+1 );
	}
	RMatrixXf r = RMatrixXf::Zero( Ns, D );
	VectorXf cnt = VectorXf::Zero( Ns );
	for( int i=0; i<N; i++ ) {
		const short s = S[i];
		if( 0 <= s && s < Ns ) {
			cnt[s] += 1;
			r.row(s) += RowVectorXf::Map( V+i*D, D );
		}
	}
	return (1.0 / cnt.array()).matrix().asDiagonal() * r;
}
void StaticBinaryCRFFeatures::makeUnary( const ImageOverSegmentation & ios ) {
	const RMatrixXs & s = ios.s();
	unary_ = RMatrixXf::Zero( ios.Ns(), unaryDim( which_ ) );
	int k = 0;
	Image im = ios.image();
// 	rgb2lab( im, ios.image() );
	if( which_ & CONSTANT )
		unary_.col(k++).setOnes();
	if( which_ & POSITION ) {
		// Mean x and y
		RMatrixXf px = VectorXf::Ones(s.rows())*RowVectorXf::LinSpaced(s.cols(),0,1);
		RMatrixXf py = VectorXf::LinSpaced(s.rows(),0,1)*RowVectorXf::Ones(s.cols());
		unary_.col(k++) = projectMean( px.data(), s.data(), s.rows()*s.cols(), 1, ios.Ns() );
		unary_.col(k++) = projectMean( py.data(), s.data(), s.rows()*s.cols(), 1, ios.Ns() );
		
		// Mean x^2 and y&2
		RMatrixXf px2 = px.array()*px.array();
		RMatrixXf py2 = py.array()*py.array();
		unary_.col(k++) = projectMean( px2.data(), s.data(), s.rows()*s.cols(), 1, ios.Ns() );
		unary_.col(k++) = projectMean( py2.data(), s.data(), s.rows()*s.cols(), 1, ios.Ns() );
		
		// Mean xy
		RMatrixXf pxy = px.array()*py.array();
		unary_.col(k++) = projectMean( pxy.data(), s.data(), s.rows()*s.cols(), 1, ios.Ns() );
	}
	if( which_ & (COLOR | BG_COLOR | COLOR_DF | COLOR_SQ) ) {
		RMatrixXf mean_color = projectMean( im.data(), s.data(), s.rows()*s.cols(), 3, ios.Ns() );
		// RGB
		if( which_ & COLOR ) {
			unary_.middleCols(k,3) = mean_color;
			k += 3;
		}
		RowVector3f bg_color = RMatrixXf::Map( im.data(), s.rows()*s.cols(), 3 ).colwise().mean();
		// Mean
		if( which_ & BG_COLOR ) {
			unary_.middleCols(k,3).rowwise() = bg_color;
			k += 3;
		}
		// RGB^2
		if( which_ & COLOR_SQ ) {
			unary_.middleCols(k,3) = mean_color.array().square();
			k += 3;
		}
		// (RGB-Mean)^2
		if( which_ & COLOR_DF ) {
			unary_.middleCols(k,3) = (mean_color.rowwise()-bg_color).array().square();
			k += 3;
		}
	}
	if( which_ & GEO_BND ) {
		VectorXf boundary_mask = VectorXf::Ones( ios.Ns() )*1e10;
		for( int i=0; i<s.rows(); i++ )
			boundary_mask[ s(i,0) ] = boundary_mask[ s(i,s.cols()-1) ] = 0;
		for( int i=0; i<s.cols(); i++ )
			boundary_mask[ s(0,i) ] = boundary_mask[ s(s.rows()-1,i) ] = 0;
		
		for( int p=0; p<4; p++ ) {
			GeodesicDistance gdist( ios.edges(), ios.edgeWeights().array().pow(p) + 1e-3 );
			unary_.col(k++) = gdist.compute(boundary_mask);
		}
	}
	eassert( k == unaryDim( which_ & ALL_STATIC_FEATURES ) );
}
void StaticBinaryCRFFeatures::makePairwise( const ImageOverSegmentation & ios ) {
	// Construct a simple pairwise features (multiple powerers of the boundary map)
	const int D = 5;
	VectorXf ew = ios.edgeWeights();
	pairwise_ = RMatrixXf::Ones( ew.size(), D );
	for( int i=1; i<D; i++ )
		pairwise_.col(i) = (-3*i*ew.array()).exp();
}
const RMatrixXf & StaticBinaryCRFFeatures::unary() const {
	return unary_;
}
const RMatrixXf & StaticBinaryCRFFeatures::pairwise() const {
	return pairwise_;
}
const Edges & StaticBinaryCRFFeatures::graph() const {
	return graph_;
}

SeedBinaryCRFFeatures::SeedBinaryCRFFeatures( const ImageOverSegmentation & ios, int which ):StaticBinaryCRFFeatures( ios, which ) {
	
	if( which_ & GEO_SEED ) {
		const Edges & e = ios.edges();
		gdist0_ = std::make_shared<GeodesicDistance>( e, ios.edgeWeights().array().pow(0)+1e-3 );
		gdist1_ = std::make_shared<GeodesicDistance>( e, ios.edgeWeights().array().pow(1)+1e-3 );
		gdist2_ = std::make_shared<GeodesicDistance>( e, ios.edgeWeights().array().pow(2)+1e-3 );
		gdist3_ = std::make_shared<GeodesicDistance>( e, ios.edgeWeights().array().pow(3)+1e-3 );
	}
	if( which_ & (COLOR_SEED | COLOR_SEED_SQ | COLOR_SEED_DF) ) {
		const RMatrixXs & s = ios.s();
		Image im = ios.image();
		mean_color_ = projectMean( im.data(), s.data(), s.rows()*s.cols(), 3, ios.Ns() );
	}
}
void SeedBinaryCRFFeatures::updateUnary( RMatrixXf & f, int s ) const {
	int k = unaryDim( which_ & ALL_STATIC_FEATURES );
	// Seed indicator
	if( which_ & SEED_INDICATOR ) {
		f.col(k).setZero();
		f(s,k) = 1;
		k++;
	}
	// Geodesic features
	if( which_ & GEO_SEED ) {
		f.col(k++) = gdist0_->compute( s );
		f.col(k++) = gdist1_->compute( s );
		f.col(k++) = gdist2_->compute( s );
		f.col(k++) = gdist3_->compute( s );
	}
	// Color features
	if( which_ & COLOR_SEED ) {
		f.middleCols(k,3).rowwise() = mean_color_.row( s );
		k += 3;
	}
	if( which_ & COLOR_SEED_SQ ) {
		f.middleCols(k,3).rowwise() = mean_color_.row( s ).array().square().matrix();
		k += 3;
	}
	if( which_ & COLOR_SEED_DF ) {
		f.middleCols(k,3) = (mean_color_.rowwise()-mean_color_.row( s )).array().square();
		k += 3;
	}
	eassert( k == unaryDim( which_ & (ALL_STATIC_FEATURES|ALL_SEED_FEATURES) ) );
}
void SeedBinaryCRFFeatures::update( int s ) {
	updateUnary( unary_, s );
}
CachedSeedBinaryCRFFeatures::CachedSeedBinaryCRFFeatures(const ImageOverSegmentation & ios, const VectorXi & seeds, int which ):SeedBinaryCRFFeatures(ios,which) {
	const int D = unaryDim( which_ & ALL_SEED_FEATURES & ~(unsigned int)SEED_INDICATOR );
	cache_ = std::make_shared< std::vector<RMatrixXf> >();
	seed_to_cache_id_ = -VectorXi::Ones( ios.Ns() );
	// Cache the features
	RMatrixXf tmp = RMatrixXf::Zero( ios.Ns(), unaryDim(which_) );
	for( int i=0; i<seeds.size(); i++ ) {
		const int s = seeds[i];
		seed_to_cache_id_[ s ] = i;
		SeedBinaryCRFFeatures::updateUnary( tmp, s );
		cache_->push_back( tmp.rightCols( D ) );
	}
}
void CachedSeedBinaryCRFFeatures::updateUnary( RMatrixXf & f, int s ) const {
	const int D = unaryDim( which_ & ALL_SEED_FEATURES & ~(unsigned int)SEED_INDICATOR );
	const int i = seed_to_cache_id_[s];
	int k = unaryDim( which_ & ALL_STATIC_FEATURES );
	// Seed indicator
	if( which_ & SEED_INDICATOR ) {
		f.col(k).setZero();
		f(s,k) = 1;
		k++;
	}
	// Geodesic features
	f.rightCols(D) = (*cache_)[i];
}
std::shared_ptr< StaticBinaryCRFFeatures > CachedSeedBinaryCRFFeatures::get( int s ) const {
	RMatrixXf unary = 1*unary_;
	updateUnary( unary, s );
	return std::shared_ptr<StaticBinaryCRFFeatures>( new StaticBinaryCRFFeatures(  unary, graph_, pairwise_, which_ ) );
}
