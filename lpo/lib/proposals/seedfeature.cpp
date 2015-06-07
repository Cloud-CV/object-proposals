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
#include "seedfeature.h"
#include "util/geodesics.h"
#include "util/util.h"
#include "segmentation/segmentation.h"
#include "imgproc/color.h"
#include "contour/directedsobel.h"
#include <tuple>
#include <queue>
#include <iostream>
#include <random>
#include <Eigen/QR>

static VectorXu8 findBoundary( const RMatrixXs & s ) {
	int Ns = s.maxCoeff()+1;
	VectorXu8 r = VectorXu8::Zero( Ns );
	for( int i=0; i<s.cols(); i++ ) r[ s(0,i) ] = 1;
	for( int i=0; i<s.cols(); i++ ) r[ s(s.rows()-1,i) ] = 2;
	for( int i=0; i<s.rows(); i++ ) r[ s(i,0) ] = 3;
	for( int i=0; i<s.rows(); i++ ) r[ s(i,s.cols()-1) ] = 4;
	return r;
}

template<typename F>
RMatrixXf bin( const RMatrixXs & s, int D, F f ) {
	const int Ns = s.maxCoeff()+1;
	RArrayXXf r = RMatrixXf::Zero( Ns, D );
	for( int j=0; j<s.rows(); j++ )
		for( int i=0; i<s.cols(); i++ )
			r.row( s(j,i) ) += f(i,j);
	return r;
}

void setVector( ArrayXf & v, int n ) {}
template<typename... ARGS> void setVector( ArrayXf & v, int n, float w, ARGS... args ) {
	if( n < v.size() ) {
		v[n] = w;
		setVector( v, n+1, args... );
	}
}
template<int N,typename... ARGS> ArrayXf makeArray( ARGS... args ) {
	ArrayXf r( N );
	setVector( r, 0, args... );
	return r;
}
// static const float EDGE_P[] = {3.f};
static const float EDGE_P[] = {0.f, 1.0f, 2.0f, 3.0f};
static const int N_STATIC_POS = 6, N_STATIC_GEO = sizeof(EDGE_P)/sizeof(EDGE_P[0]), N_STATIC_EDGE = 0;
static const int N_OBJ_EDGE = 10, N_OBJ_COL = 9, N_OBJ_COL_DIFF = 9, N_OBJ_CONTEXT = 1, N_OBJ_POS = 4;
static const int N_OBJ_F = (N_OBJ_CONTEXT+1)*(N_OBJ_EDGE+N_OBJ_COL+N_OBJ_COL_DIFF+N_OBJ_POS)+1/*const*/;
static const int N_DYNAMIC_HAS_SEED = 0, N_DYNAMIC_COL = 11, N_DYNAMIC_GEO = sizeof(EDGE_P)/sizeof(EDGE_P[0]);
static const int N_STATIC_F = N_STATIC_POS + N_STATIC_GEO + N_STATIC_EDGE + (N_OBJ_F>1);
static const int N_DYNAMIC_F = N_DYNAMIC_HAS_SEED + N_DYNAMIC_COL + N_DYNAMIC_GEO;

SeedFeature::SeedFeature( const ImageOverSegmentation & ios, const VectorXf & obj_param ) {
	Image rgb_im = ios.image();
	const RMatrixXs & s = ios.s();
	const int Ns = ios.Ns(), W = rgb_im.W(), H = rgb_im.H();

	// Initialize various values
	VectorXf area  = bin( s, 1, [&](int x, int y) {
		return 1.f;
	} );
	VectorXf norm = (area.array()+1e-10).cwiseInverse();
	pos_ = norm.asDiagonal() * bin( s, 6, [&](int i, int j) {
		float x=1.0*i/(W-1)-0.5,y=1.0*j/(H-1)-0.5;
		return makeArray<6>( x, y, x*x, y*y, fabs(x), fabs(y) );
	} );
	if (N_DYNAMIC_COL) {
		Image lab_im;
		rgb2lab( lab_im, rgb_im );
		col_ = norm.asDiagonal() * bin( s, 6, [&](int x, int y) {
			return makeArray<6>( rgb_im(y,x, 0), rgb_im(y,x,1), rgb_im(y,x,2), lab_im(y,x,0), lab_im(y,x,1), lab_im(y,x,2) );
		} );
	}

	const int N_GEO = sizeof(EDGE_P)/sizeof(EDGE_P[0]);
	for( int i=0; i<N_GEO; i++ )
		gdist_.push_back( GeodesicDistance(ios.edges(),ios.edgeWeights().array().pow(EDGE_P[i])+1e-3) );

	// Compute the static features
	static_f_ = RMatrixXf::Zero( Ns, N_STATIC_F );
	int o=0;
	// Add the position features
	static_f_.block( 0, o, Ns, N_STATIC_POS ) = pos_.leftCols( N_STATIC_POS );
	o += N_STATIC_POS;
	// Add the geodesic features
	if( N_STATIC_GEO >= N_GEO ) {
		RMatrixXu8 bnd = findBoundary( s );
		RMatrixXf mask = (bnd.array() == 0).cast<float>()*1e10;
		for( int i=0; i<N_GEO; i++ )
			static_f_.col( o++ ) = gdist_[i].compute( mask );
		for( int j=1; (j+1)*N_GEO<=N_STATIC_GEO; j++ ) {
			mask = (bnd.array() != j).cast<float>()*1e10;
			for( int i=0; i<N_GEO; i++ )
				static_f_.col( o++ ) = gdist_[i].compute( mask );
		}
	}
	if( N_STATIC_EDGE ) {
		RMatrixXf edge_map = DirectedSobel().detect( ios.image() );
		for( int j=0; j<s.rows(); j++ )
			for( int i=0; i<s.cols(); i++ ) {
				const int id = s(j,i);
				int bin = edge_map(j,i)*N_STATIC_EDGE;
				if ( bin < 0 ) bin = 0;
				if ( bin >= N_STATIC_EDGE ) bin = N_STATIC_EDGE-1;
				static_f_(id,o+bin) += norm[id];
			}
		o += N_STATIC_EDGE;
	}
	if( N_OBJ_F>1 )
		static_f_.col(o++) = (computeObjFeatures(ios)*obj_param).transpose();

	// Initialize the dynamic features
	dynamic_f_ = RMatrixXf::Zero( Ns, N_DYNAMIC_F );
	n_ = 0;
	min_dist_ = RMatrixXf::Ones(Ns,5)*10;
	var_      = RMatrixXf::Zero(Ns,6);
}
RMatrixXf SeedFeature::computeObjFeatures( const ImageOverSegmentation & ios ) {
	Image rgb_im = ios.image();
	const RMatrixXs & s = ios.s();
	const Edges & g = ios.edges();
	const int Ns = ios.Ns();

	RMatrixXf r = RMatrixXf::Zero( Ns, N_OBJ_F );
	if( N_OBJ_F<=1 ) return r;
	VectorXf area  = bin( s, 1, [&](int x, int y) {
		return 1.f;
	} );
	VectorXf norm = (area.array()+1e-10).cwiseInverse();

	r.col(0).setOnes();
	int o = 1;
	if (N_OBJ_COL>=6) {
		Image lab_im;
		rgb2lab( lab_im, rgb_im );
		r.middleCols(o,6) = norm.asDiagonal() * bin( s, 6, [&](int x, int y) {
			return makeArray<6>( lab_im(y,x,0), lab_im(y,x,1), lab_im(y,x,2), lab_im(y,x,0)*lab_im(y,x,0), lab_im(y,x,1)*lab_im(y,x,1), lab_im(y,x,2)*lab_im(y,x,2) );
		} );
		RMatrixXf col = r.middleCols(o,3);
		if( N_OBJ_COL >= 9)
			r.middleCols(o+6,3) = col.array().square();
		o += N_OBJ_COL;

		// Add color difference features
		if( N_OBJ_COL_DIFF ) {
			RMatrixXf bcol = RMatrixXf::Ones( col.rows(), col.cols()+1 );
			bcol.leftCols(3) = col;
			for( int it=0; it*3+2<N_OBJ_COL_DIFF; it++ ) {
				// Apply a box filter on the graph
				RMatrixXf tmp = bcol;
				for( const auto & e: g ) {
					tmp.row(e.a) += bcol.row(e.b);
					tmp.row(e.b) += bcol.row(e.a);
				}
				bcol = tmp.col(3).cwiseInverse().asDiagonal()*tmp;
				r.middleCols(o,3) = (bcol.leftCols(3)-col).array().abs();
				o += 3;
			}
		}
	}
	if( N_OBJ_POS >= 2 ) {
		RMatrixXf xy = norm.asDiagonal() * bin( s, 2, [&](int x, int y) {
			return makeArray<2>( 1.0*x/(s.cols()-1)-0.5, 1.0*y/(s.rows()-1)-0.5 );
		} );
		r.middleCols(o,2) = xy;
		o+=2;
		if( N_OBJ_POS >=4 ) {
			r.middleCols(o,2) = xy.array().square();
			o+=2;
		}
	}
	if( N_OBJ_EDGE ) {
		RMatrixXf edge_map = DirectedSobel().detect( rgb_im );
		for( int j=0; j<s.rows(); j++ )
			for( int i=0; i<s.cols(); i++ ) {
				const int id = s(j,i);
				int bin = edge_map(j,i)*N_OBJ_EDGE;
				if ( bin < 0 ) bin = 0;
				if ( bin >= N_OBJ_EDGE ) bin = N_OBJ_EDGE-1;
				r(id,o+bin) += norm[id];
			}
		o += N_OBJ_EDGE;
	}
	const int N_BASIC = o-1;
	// Add in context features
	for( int i=0; i<N_OBJ_CONTEXT; i++ ) {
		const int o0 = o - N_BASIC;
		// Box filter the edges
		RMatrixXf f = RMatrixXf::Ones( Ns, N_BASIC+1 ), bf = RMatrixXf::Zero( Ns, N_BASIC+1 );
		f.rightCols( N_BASIC ) = r.middleCols(o0,N_BASIC);
		for( Edge e: g ) {
			bf.row(e.a) += f.row(e.b);
			bf.row(e.b) += f.row(e.a);
		}
		r.middleCols(o,N_BASIC) = bf.col(0).array().max(1e-10f).inverse().matrix().asDiagonal() * bf.rightCols(N_BASIC);
		o += N_BASIC;
	}
	return r;
}
void SeedFeature::update( int n ) {
	const float loc_w = 1.0;
	// compute the dynamic features
	int o=0;
	if( N_DYNAMIC_HAS_SEED ) {
		dynamic_f_(n,o++) = 1;
	}
	if( N_DYNAMIC_GEO>=gdist_.size() )
		for( int i=0; i<gdist_.size(); i++ )
			dynamic_f_.col(o++) = gdist_[i].update( n ).d();

	if( N_DYNAMIC_COL ) {
		RowVectorXf col = col_.row(n);
		for( int i=0; i<col_.rows(); i++ ) {
			RowVectorXf cd = (col_.row(i)-col).array().square().matrix();
			var_.row(i) += cd;

			if( N_DYNAMIC_COL >= 11 ) {
				float c1 = sqrt(cd.head(3).sum()), c2 = sqrt(cd.tail(3).sum()), d = (pos_.row(n).head(2)-pos_.row(i).head(2)).norm();
				min_dist_(i,0) = std::min( min_dist_(i,0), c1 );
				min_dist_(i,1) = std::min( min_dist_(i,1), c2 );
				min_dist_(i,2) = std::min( min_dist_(i,2), c1+loc_w*d );
				min_dist_(i,3) = std::min( min_dist_(i,3), c2+loc_w*d );
				min_dist_(i,4) = std::min( min_dist_(i,4), d );
			}
		}
		n_++;
		if( N_DYNAMIC_COL >= 6 ) {
			dynamic_f_.middleCols(o,6) = var_ / n_;
			o += 6;
		}
		if( N_DYNAMIC_COL >= 11 ) {
			dynamic_f_.middleCols(o,5) = min_dist_;
			o += 5;
		}
	}
}
int SeedFeature::cols() const {
	return static_f_.cols() + dynamic_f_.cols();
}
int SeedFeature::rows() const {
	return static_f_.rows();
}
VectorXf SeedFeature::operator*( const VectorXf & o ) const {
	eassert( o.size() == static_f_.cols() + dynamic_f_.cols() );
	return static_f_*o.head(static_f_.cols()) + dynamic_f_*o.tail(dynamic_f_.cols());
}
RowVectorXf operator*(const RowVectorXf& o, const SeedFeature& f) {
	eassert( o.size() == f.static_f_.rows() );
	RowVectorXf r( f.static_f_.cols() + f.dynamic_f_.cols() );
	r.head(f.static_f_.cols())  = o * f.static_f_;
	r.tail(f.dynamic_f_.cols()) = o * f.dynamic_f_;
	return r;
}

SeedFeature SeedFeatureFactory::make( const ImageOverSegmentation & ios ) const {
	return SeedFeature( ios, param_ );
}
void SeedFeatureFactory::train( const std::vector< std::shared_ptr<ImageOverSegmentation> > &ios, const std::vector<VectorXs> & lbl ) {
	printf("  * Training SeedFeature\n");
	static std::mt19937 rand;
	const int N_SAMPLES = 5000;
	int n_pos=0, n_neg=0;
	for( VectorXs l: lbl ) {
		n_pos += (l.array()>=0).cast<int>().sum();
		n_neg += (l.array()==-1).cast<int>().sum();
	}

	// Collect training examples
	float sampling_freq[] = {0.5f*N_SAMPLES / n_neg, 0.5f*N_SAMPLES / n_pos};
	std::vector<RowVectorXf> f;
	std::vector<float> l;
	#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ ) {
		RMatrixXf ftr = SeedFeature::computeObjFeatures( *ios[i] );
		for( int j=0; j<ios[i]->Ns(); j++ )
			if( lbl[i][j] >= -1 && rand() < rand.max()*sampling_freq[ lbl[i][j]>=0 ] ) {
				#pragma omp critical
				{
					l.push_back( lbl[i][j]>=0 );
					f.push_back( ftr.row(j) );
				}
			}
	}

	printf("    - Computing parameters\n");
	// Fit the ranking functions
	RMatrixXf A( f.size(), f[0].size() );
	VectorXf b( l.size() );
	for( int i=0; i<f.size(); i++ ) {
		A.row(i) = f[i];
		b[i] = l[i];
	}

	// Solve A*x = b
	param_ = A.colPivHouseholderQr().solve(b);
	printf("    - done %f\n",(A*param_-b).array().abs().mean());
}
void SeedFeatureFactory::load( std::istream & is ) {
	loadMatrixX( is, param_ );
}
void SeedFeatureFactory::save( std::ostream & os ) const {
	saveMatrixX( os, param_ );
}
SeedFeature::operator RMatrixXf() const {
	RMatrixXf r(static_f_.rows(), static_f_.cols()+dynamic_f_.cols());
	r.leftCols( static_f_.cols() ) = static_f_;
	r.rightCols( dynamic_f_.cols() ) = dynamic_f_;
	return r;
}

