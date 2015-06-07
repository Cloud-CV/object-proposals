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
#include "seed.h"
#include "util/geodesics.h"
#include "util/algorithm.h"
#include "util/optimization.h"
#include "segmentation/segmentation.h"
#include <queue>
#include <unordered_map>
#include <iostream>
#include <fstream>
#include <random>

SeedFunction::~SeedFunction() {
}
void SeedFunction::save(std::ostream &s) const {
}
void SeedFunction::load(std::istream &s) {
}
VectorXi ImageSeedFunction::compute(const OverSegmentation &os, int M) const {
	try {
		return computeImageOverSegmentation( dynamic_cast<const ImageOverSegmentation&>( os ), M );
	} catch (std::bad_cast e) {
		throw std::invalid_argument("Image seed function not supported for ImageOverSegmentation.");
	}
}

VectorXi RegularSeed::computeImageOverSegmentation(  const ImageOverSegmentation & ios, int M ) const {
	// Pick the seeds on a regular grid (only supported on images)
	VectorXi r( M );
	const RMatrixXs & s = ios.s();
	int ny = std::max( (int)(sqrt(1.0*M*s.rows()/s.cols())+0.5), 1 );
	for( int j=0,k=0; j<ny; j++ ) {
		int i0 = j*M/ny, i1 = (j+1)*M/ny;
		for( int i=i0; i<i1; i++,k++ )
			r[k] = s( (int)((j+0.5)/ny*s.rows()), (int)((i-i0+0.5)/(i1-i0)*s.cols()) );
	}
	return r;
}
GeodesicSeed::GeodesicSeed( float pow, float const_w, float min_d ) : pow_(pow), const_w_(const_w), min_d_( min_d ) {
}
VectorXi GeodesicSeed::compute( const OverSegmentation & os, int M ) const {
	VectorXi seeds( M );
	// Place the first seed in the geodesic center
	const Edges & edges = os.edges();
	VectorXf ew = os.edgeWeights().array().pow( pow_ ) + const_w_;
	seeds[0] = geodesicCenter( edges, ew );
	GeodesicDistance gdist( edges, ew );
	gdist.update( seeds[0] );
	// Place all other seeds at the max geodesic distance
	for( int it=1; it<M; it++ ) {
		float d = gdist.d().maxCoeff( &seeds[it] );
		if( d <= min_d_ ) {
			// Stop early
			return seeds.head( it );
		}
		if( it+1<M )
			gdist.update( seeds[it] );
	}
	return seeds;
}
void GeodesicSeed::save(std::ostream &s) const {
	float param[3] = {pow_, const_w_, min_d_};
	s.write( (const char*)param, sizeof(param) );
}
void GeodesicSeed::load(std::istream &s) {
	float param[3];
	s.read( (char*)param, sizeof(param) );
	pow_ = param[0];
	const_w_ = param[1];
	min_d_ = param[2];
}
VectorXi RandomSeed::compute( const OverSegmentation & os, int M ) const {
	// Pick the seeds randomly
	return randomChoose( os.Ns(), M );
}
LearnedSeed::LearnedSeed() {
}
LearnedSeed::LearnedSeed(const std::string& fn) {
	load( fn );
}
void LearnedSeed::train( const std::vector< std::shared_ptr<ImageOverSegmentation> > &ios, const std::vector<VectorXs> & lbl, int max_feature, int n_seed_per_obj ) {
	f_.train( ios, lbl );
	std::vector< SeedFeature > f;
	for( auto g: ios )
		f.push_back( f_.make( *g ) );
	trainFromFeatures( f, lbl, max_feature, n_seed_per_obj );
}
class LogLogisticSeedTrainer: public EnergyFunction {
protected:
	std::vector<int> ids_;
	const std::vector<SeedFeature> & f_;
	const std::vector<VectorXb> & l_;
	VectorXf initial_guess_;
public:
	LogLogisticSeedTrainer( const std::vector<SeedFeature> & f, const std::vector<VectorXb> & l, const std::vector<bool> & active ): f_(f), l_(l) {
		for( int i=0; i<(int)active.size(); i++ )
			if( active[i] )
				ids_.push_back( i );

		const int N = f_[0].cols();
		initial_guess_ = VectorXf::Zero( N );
	}
	void setInitialGuess( const VectorXf & g ) {
		initial_guess_ = g;
	}
	virtual VectorXf initialGuess() const {
		return initial_guess_;
	}
	virtual VectorXf gradient(const VectorXf &x, float &e) const {
		const float L2_norm = 0;
		e = 0;
		double se = 0;
		VectorXf g = 0*x;
		#pragma omp parallel for
		for( int i=0; i<(int)ids_.size(); i++ ) {
			int id = ids_[i];
			// Compute the response
// 			VectorXf fx = f_[id] * x;
			RMatrixXf fm = ((RMatrixXf)f_[id]);
			// Subtract the colwise mean (to make things more numerically stable) [might need to do it a few times]
			fm.rowwise() -= fm.colwise().mean();
			fm.rowwise() -= fm.colwise().mean();
			fm.rowwise() -= fm.colwise().mean();
			VectorXf fx = fm * x;

			// Compute the positive prob dist
			int n_pos = l_[id].array().cast<int>().sum();
			VectorXf fx_pos( n_pos );
			for( int j=0,k=0; j<fx.size(); j++ )
				if( l_[id][j] )
					fx_pos[k++] = fx[j];

			// Compute the distribution
			float mx = fx.maxCoeff(), mx_pos = fx_pos.maxCoeff();
			VectorXf efx = (fx.array()-mx).exp(), efx_pos = (fx_pos.array()-mx_pos).exp();
			// Update the energy
			#pragma omp atomic
			se -= log(efx_pos.array().sum())+mx_pos - (log(efx.array().sum())+mx);

			// Update the gradient
			efx.array() /= efx.array().sum();
			efx_pos.array() /= efx_pos.array().sum();
			RowVectorXf d = efx.transpose();
			for( int j=0,k=0; j<efx.size(); j++ )
				if( l_[id][j] )
					d[j] -= efx_pos[k++];
			VectorXf gg = -(d*fm).transpose();

			#pragma omp critical
			g -= gg;
		}
		e = se + 0.5*L2_norm*x.squaredNorm();
		g += L2_norm*x;
		return g;
	}
};
void LearnedSeed::trainFromFeatures(std::vector< SeedFeature > &f, const std::vector<VectorXs> & lbl, int max_seed, int n_seed_per_obj ) {
	const int N_SEED_PER_SEG = n_seed_per_obj;
// 	printf("# RANDOM = %d\n", N_SEED_PER_SEG );
	// Initialize the labels
	std::vector< VectorXb > l( lbl.size() );
	std::vector< bool > active( lbl.size() );
	std::vector< VectorXs > hit( lbl.size() );
	int n_obj = 0, n_got_tot = 0;
	for( int i=0; i<lbl.size(); i++ ) {
		n_obj += lbl[i].maxCoeff()+1;
		hit[i] = VectorXs::Zero( lbl[i].maxCoeff()+1 );
		l[i] = lbl[i].array()>=0;
		active[i] = l[i].any();
	}
	for( int it=0; it<max_seed && n_got_tot<n_obj; it++ ) {
		LogLogisticSeedTrainer trainer( f, l, active );
		// Maybe a few random initiaziations would work better
		float e;
		VectorXf best_w;
		int best_got=-1;
		for( int n_init=0; n_init<5; n_init++ ) {
			if( n_init>0 )
				trainer.setInitialGuess( VectorXf::Random(trainer.initialGuess().size()) );
			VectorXf new_w = minimizeLBFGS( trainer, e, 0 );
			// Do a few restarts
			for ( int n_restart=0; n_restart<2; n_restart++ ) {
				trainer.setInitialGuess( new_w );
				new_w = minimizeLBFGS( trainer, e, 0 );
			}

			int n_got = 0;
			// Update the seeds and features
			for( int i=0; i<lbl.size(); i++ )
				if( active[i] ) {
					// Compute the response
// 					VectorXf fw = f[i]*new_w;
					RMatrixXf fm = ((RMatrixXf)f[i]);
					// Subtract the colwise mean (to make things more numerically stable) [might need to do it a few times]
					fm.rowwise() -= fm.colwise().mean();
					fm.rowwise() -= fm.colwise().mean();
					fm.rowwise() -= fm.colwise().mean();
					VectorXf fw = fm*new_w;

					int mx=0;
					fw.maxCoeff( &mx );

					// Remove the current segment (or part of it)
					if( l[i][mx] )
						n_got++;
				}
			if( n_got > best_got ) {
				best_got = n_got;
				best_w = new_w;
			}
		}
		// Update the features
		int n_got = 0, n_active = 0;
		// Update the seeds and features
		for( int i=0; i<lbl.size(); i++ )
			if( active[i] ) {
				// Compute the response
				RMatrixXf fm = ((RMatrixXf)f[i]);
				// Subtract the colwise mean (to make things more numerically stable) [might need to do it a few times]
				fm.rowwise() -= fm.colwise().mean();
				fm.rowwise() -= fm.colwise().mean();
				fm.rowwise() -= fm.colwise().mean();
				VectorXf fw = fm*best_w;
// 				VectorXf fw = f[i]*best_w;
				int mx=0;
				fw.maxCoeff( &mx );

				// Update the feature
				f[i].update( mx );

				n_active += active[i];
				// Remove the current segment (or part of it)
				if( l[i][mx] ) {
					hit[i][ lbl[i][mx] ] += 1;
					l[i][mx] = 0;
					if ( hit[i][ lbl[i][mx] ] >= N_SEED_PER_SEG ) {
						for( int k=0; k<l[i].size(); k++ )
							if(l[i][k] && lbl[i][k] == lbl[i][mx]) {
								// Update the weight and label
								l[i][k] = 0;
							}
						active[i] = l[i].any();
						n_got++;
					}
				}
			}


		// Add the learned feature
		w_.push_back( best_w );
		n_got_tot += n_got;
		printf("[%3d]  Total objects %5.1f%%       Got %4d / %4d objects\r", it, 100.*n_got_tot/n_obj, n_got,n_active );
		fflush( stdout );
	}
	printf("\nTraining got %d / %d objects: %0.1f%%                            \n", n_got_tot, n_obj, 100.*n_got_tot/n_obj );
}
VectorXi LearnedSeed::computeImageOverSegmentation( const ImageOverSegmentation & ios, int M ) const {
	SeedFeature f = f_.make( ios );
	VectorXb used = VectorXb::Zero( ios.Ns() );
	std::vector<int> r;
	for( int i=0; i<M && i<w_.size(); i++ ) {
		int mx=0;
		VectorXf fw = f*w_[i];
		fw.maxCoeff( &mx );
		if( !used[mx] ) {
			used[mx] = 1;
			r.push_back( mx );
		}

		f.update( mx );
	}
	return VectorXi::Map( r.data(), r.size() );
}
void LearnedSeed::load(std::istream &s) {
	f_.load(s);
	w_ = loadVector<VectorXf>( s );
}
void LearnedSeed::save(std::ostream &s) const {
	f_.save(s);
	saveVector<VectorXf>( s, w_ );
}
void LearnedSeed::load(const std::string &s) {
	std::ifstream is(s, std::ios::in | std::ios::binary);
	if(!is.is_open())
		throw std::invalid_argument( "Could not open file '"+s+"'!" );
	load(is);
}
void LearnedSeed::save(const std::string &s) const {
	std::ofstream os(s, std::ios::out | std::ios::binary);
	if(!os.is_open())
		throw std::invalid_argument( "Could not write file '"+s+"'!" );
	save(os);
}
enum SeedType {
    REGULAR=0,
    RANDOM,
    GEODESIC,
    LEARNED
};
void saveSeed(std::ostream & os, const std::shared_ptr< SeedFunction >& s) {
	int id = -1;
	if( std::dynamic_pointer_cast<RegularSeed>( s ) )      id = REGULAR;
	if( std::dynamic_pointer_cast<RandomSeed>( s ) )       id = RANDOM;
	if( std::dynamic_pointer_cast<GeodesicSeed>( s ) )     id = GEODESIC;
	if( std::dynamic_pointer_cast<LearnedSeed>( s ) )      id = LEARNED;
	os.write( (const char*)&id, sizeof(id) );
	s->save( os );
}
std::shared_ptr< SeedFunction > loadSeed(std::istream& is) {
	int id = 0;
	is.read( (char*)&id, sizeof(id) );
	std::shared_ptr<SeedFunction> s;
	if( id == REGULAR      ) s = std::make_shared<RegularSeed>();
	if( id == RANDOM       ) s = std::make_shared<RandomSeed>();
	if( id == GEODESIC     ) s = std::make_shared<GeodesicSeed>();
	if( id == LEARNED      ) s = std::make_shared<LearnedSeed>();
	if( s )
		s->load( is );
	return s;
}
