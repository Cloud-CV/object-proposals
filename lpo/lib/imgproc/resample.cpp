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
#include "resample.h"
#include "util/util.h"
#include <vector>

template<int C>
static void downsample2( float *res, const float *im, int W, int H, int NW, int NH ) {
	const int h_nbrs = H/NH, w_nbrs = W/NW;
	eassert( h_nbrs == 2 && w_nbrs == 2 );
	bool use_sse = 1 < C && C <= 4;
	for(int nj = 0; nj < NH; nj++) {
		for(int ni = 0; ni < NW; ni++) {
			float * pres = res + (nj*NW+ni)*C;
			int id = ((2*ni) + (2*nj)*W)*C;
			if( use_sse ) {
				__m128 sm = _mm_set1_ps(0.f);
				sm += _mm_loadu_ps( im+id );
				if( 2*ni+1 < W )
					sm += _mm_loadu_ps( im+id+C );
				if( 2*nj+1 < H )
					sm += _mm_loadu_ps( im+id+C*W );
				if( 2*ni+1 < W && 2*nj+1 < H )
					sm += _mm_loadu_ps( im+id+C+C*W );
				sm *= _mm_set1_ps(0.25f);
				for(int c = 0; c < C; c++)
					pres[c] = sm[c];
			} else {
				for(int c = 0; c < C; c++ )
					pres[c] = im[id+c];
				if( 2*ni+1 < W )
					for(int c = 0; c < C; c++ ) pres[c] += im[id+C+c];
				if( 2*nj+1 < H )
					for(int c = 0; c < C; c++ ) pres[c] += im[id+C*W+c];
				if( 2*ni+1 < W && 2*nj+1 < H )
					for(int c = 0; c < C; c++ ) pres[c] += im[id+C*W+C+c];
				for(int c = 0; c < C; c++)
					pres[c] *= 0.25;
			}
		}
	}
}
template<int C>
static void downsample( float *res, const float *im, int W, int H, int NW, int NH ) {
	const int h_nbrs = H/NH, w_nbrs = W/NW;
	if( h_nbrs == 2 && w_nbrs == 2 )
		return downsample2<C>( res, im, W, H, NW, NH );
	memset( res, 0, NW*NH*C*sizeof(float));
	for(int j = 0; j < H; j++) {
		for(int i = 0; i < W; i++) {
			const int ni = i*NW/W, nj = j*NH/H;
			for(int c = 0; c < C; c++)
				res[nj*NW*C + ni*C + c] += im[j*W*C + i*C + c] / (h_nbrs*w_nbrs);
		}
	}
}
RMatrixXf downsample( const RMatrixXf & image, int NW, int NH ) {
	RMatrixXf res( NH, NW );
	downsample<1>( res.data(), image.data(), image.cols(), image.rows(), NW, NH );
	return res;
}
void downsample( Image & r, const Image & image, int NW, int NH ) {
	r.create( NW, NH, image.C() );
	eassert( image.C() <= 8 );
	if( image.C()==1 ) downsample<1>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==2 ) downsample<2>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==3 ) downsample<3>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==4 ) downsample<4>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==5 ) downsample<5>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==6 ) downsample<6>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==7 ) downsample<7>( r.data(), image.data(), image.W(), image.H(), NW, NH );
	if( image.C()==8 ) downsample<8>( r.data(), image.data(), image.W(), image.H(), NW, NH );
}
Image downsample( const Image & image, int NW, int NH ) {
	Image res( NW, NH, image.C() );
	downsample( res, image, NW, NH );
	return res;
}
template<typename T>
static void resize( T *res, const T *im, int W, int H, int NW, int NH, int C ) {
	const float dy = 1.0*(H-1)/(NH-1), dx = 1.0*(W-1)/(NW-1);
	memset( res, 0, NW*NH*C*sizeof(T));
	for(int j = 0; j < NH; j++) {
		for(int i = 0; i < NW; i++) {
			const int i0 = i*dx       , j0 = j*dy;
			const int i1 = i0+(i0<W-1), j1 = j0+(j0<H-1);
			const float wi = i*dx-i0  , wj = j*dy-j0;
			for(int c = 0; c < C; c++)
				res[j*NW*C + i*C + c] = (1-wj)*( (1-wi)*im[j0*W*C+i0*C+c] + wi*im[j0*W*C+i1*C+c] ) +
				                        (wj  )*( (1-wi)*im[j1*W*C+i0*C+c] + wi*im[j1*W*C+i1*C+c] );
		}
	}
}
RMatrixXf resize( const RMatrixXf & image, int NW, int NH ) {
	RMatrixXf res( NH, NW );
	resize( res.data(), image.data(), image.cols(), image.rows(), NW, NH, 1 );
	return res;
}
Image resize( const Image & image, int NW, int NH ) {
	Image res( NW, NH, image.C() );
	resize( res.data(), image.data(), image.W(), image.H(), NW, NH, image.C() );
	return res;
}
Image8u resize( const Image8u & image, int NW, int NH ) {
	Image8u res( NW, NH, image.C() );
	resize( res.data(), image.data(), image.W(), image.H(), NW, NH, image.C() );
	return res;
}
void padIm( Image & r, const Image & im, int R ) {
	const int W = im.W(), H = im.H(), C = im.C();
	const int pW = W+2*R, pH=H+2*R;
	r.create( pW, pH, C );
	// Pad the image
	for( int j=0; j<H; j++ ) {
		float * pad_p = r.data()+(j+R)*pW*C;
		const float * im_p = im.data()+j*W*C;
		memcpy( pad_p+R*C, im_p, W*C*sizeof(float) );
		// Pad in x
		for( int i=0; i<R; i++ )
			memcpy( pad_p+i*C, im_p+(R-1-i)*C, C*sizeof(float) );
		for( int i=0; i<R; i++ )
			memcpy( pad_p+(R+W+i)*C, im_p+(W-1-i)*C, C*sizeof(float) );
	}
	// Pad in y
	for( int i=0; i<R; i++ )
		memcpy( r.data()+i*C*pW, r.data()+(2*R-1-i)*C*pW, C*pW*sizeof(float) );
	for( int i=0; i<R; i++ )
		memcpy( r.data()+(R+H+i)*C*pW, r.data()+(R+H-1-i)*C*pW, C*pW*sizeof(float) );
}
Image padIm( const Image & im, int R ) {
	Image r;
	padIm( r, im, R );
	return r;
}
template<typename T> void extractPatches( std::vector<T> & r, const T & m, const RMatrixXi & ids, int W, int H ) {
	const int N = ids.rows();
	int k0 = r.size();
	r.resize( k0 + N );
	for( int i=0; i<N; i++ )
		r[k0+i] = m.block( ids(i,0), ids(i,1), H, W );
}
template<typename T> void extractPatches( std::vector<T> & r, const std::vector<T> & m, const RMatrixXi & ids, int W, int H ) {
	for( int k=0; k<m.size(); k++ ) {
		const int N = (ids.col(0).array()==k).cast<int>().sum();
		if( N ) {
			// Remove the first ids dimension
			RMatrixXi new_ids( N, 2 );
			for( int i=0,j=0; i<ids.rows(); i++ )
				if( ids(i,0) == k ) {
					new_ids(j,0) = ids(i,1);
					new_ids(j,1) = ids(i,2);
					j++;
				}
			extractPatches( r, m[k], new_ids, W, H );
		}
	}
}
std::vector<RMatrixXb> extractPatches( const RMatrixXb & m, const RMatrixXi & ids, int W, int H ) {
	std::vector<RMatrixXb> r;
	extractPatches( r, m, ids, W, H );
	return r;
}
std::vector<RMatrixXs> extractPatches( const RMatrixXs & m, const RMatrixXi & ids, int W, int H ) {
	std::vector<RMatrixXs> r;
	extractPatches( r, m, ids, W, H );
	return r;
}
std::vector<RMatrixXb> extractPatches( const std::vector<RMatrixXb> & m, const RMatrixXi & ids, int W, int H ) {
	std::vector<RMatrixXb> r;
	extractPatches( r, m, ids, W, H );
	return r;
}
std::vector<RMatrixXs> extractPatches( const std::vector<RMatrixXs> & m, const RMatrixXi & ids, int W, int H ) {
	std::vector<RMatrixXs> r;
	extractPatches( r, m, ids, W, H );
	return r;
}

