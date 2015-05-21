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
#include "util/win_util.h"
#include "gradient.h"
#include "filter.h"
#include <stdexcept>
#include <iostream>
#include <Eigen/Core>
using namespace Eigen;

static const float * acosTable(){
	static float table[2001];
	static bool init = false;
	float * r = table+1000;
	if( init ) return r;
	for( int i=-1000; i<1001; i++ )
		r[i] = acos( i / 1000. );
	init = 1;
	return r;
}

static void computeGradientOriAndMag( float * g, float * o, const float * gx, const float * gy, int N, int C ) {
	const float * acost = acosTable();
	RArrayXXf mag( N, C );
	float * pm = mag.data();
	
	// mag = gx**2 + gy**2
	int i=0;
	for( ; i+3<N*C; i+=4 ){ __m128 dx = _mm_loadu_ps(gx+i); __m128 dy = _mm_loadu_ps(gy+i); _mm_storeu_ps( pm+i, dx*dx+dy*dy ); }
	for( ; i<N*C; i++ ){ pm[i] = gx[i]*gx[i]+gy[i]*gy[i]; }
	
	i=0;
	for( ; i+3<N; i+=4 ) {
		int j[4]={0};
		__m128 gm;
		gm[0] = mag.row(i+0).maxCoeff(&j[0]);
		gm[1] = mag.row(i+1).maxCoeff(&j[1]);
		gm[2] = mag.row(i+2).maxCoeff(&j[2]);
		gm[3] = mag.row(i+3).maxCoeff(&j[3]);
		gm = _mm_max_ps( _mm_sqrt_ps(gm), _mm_set1_ps(1e-10f) );
		__m128 cm = _mm_set_ps( gx[j[3]+(i+3)*C], gx[j[2]+(i+2)*C], gx[j[1]+(i+1)*C], gx[j[0]+(i+0)*C] ) / gm;

		// Change the sign
		cm = _mm_xor_ps( cm, _mm_and_ps( _mm_set1_ps(-0.f),_mm_cmple_ps( _mm_set_ps( gy[j[3]+(i+3)*C], gy[j[2]+(i+2)*C], gy[j[1]+(i+1)*C], gy[j[0]+(i+0)*C] ), _mm_set1_ps(-0.f) ) ) );
		cm = _mm_max_ps( _mm_set1_ps(-1), _mm_min_ps( cm, _mm_set1_ps(1.f) ) );
		
		o[i+0] = acost[(int)(cm[0]*1000)];
		o[i+1] = acost[(int)(cm[1]*1000)];
		o[i+2] = acost[(int)(cm[2]*1000)];
		o[i+3] = acost[(int)(cm[3]*1000)];
		g[i+0] = gm[0];
		g[i+1] = gm[1];
		g[i+2] = gm[2];
		g[i+3] = gm[3];
	}
	for( ; i<N; i++ ) {
		int j=0;
		float m = mag.row(i).maxCoeff(&j);
		float gm = std::max((float)sqrt(m),1e-10f);
		float cm = gx[i*C+j] / gm;
		if( gy[i*C+j] <= -0 ) cm = -cm;
		if( cm > 1 )  cm = 1;
		if( cm < -1 ) cm = -1;
		
		o[i] = acost[(int)(cm*1000)];
		g[i] = gm;
	}
}
// static void computeGradientMag( float * g, const float * gx, const float * gy, int N, int C ) {
// 	Map<const ArrayXXf> mgx( gx, C, N ), mgy( gy, C, N );
// 	Map<VectorXf>(g,N) = (mgx.square()+mgy.square()).colwise().maxCoeff().sqrt();
// }

static void computeGradientMag( float * g, const float * gx, const float * gy, int N, int C ) {
	RArrayXXf mag( N, C );
	float * pm = mag.data();
	
	// mag = gx**2 + gy**2
	int i=0;
	for( ; i+3<N*C; i+=4 ){ __m128 dx = _mm_loadu_ps(gx+i); __m128 dy = _mm_loadu_ps(gy+i); _mm_storeu_ps( pm+i, dx*dx+dy*dy ); }
	for( ; i<N*C; i++ ){ pm[i] = gx[i]*gx[i]+gy[i]*gy[i]; }
	
	i=0;
	for( ; i+3<N; i+=4 ) {
		int j[4]={0};
		__m128 gm;
		gm[0] = mag.row(i+0).maxCoeff(&j[0]);
		gm[1] = mag.row(i+1).maxCoeff(&j[1]);
		gm[2] = mag.row(i+2).maxCoeff(&j[2]);
		gm[3] = mag.row(i+3).maxCoeff(&j[3]);
		gm = _mm_max_ps( _mm_sqrt_ps(gm), _mm_set1_ps(1e-10f) );

		g[i+0] = gm[0];
		g[i+1] = gm[1];
		g[i+2] = gm[2];
		g[i+3] = gm[3];
	}
	for( ; i<N; i++ ) {
		int j=0;
		float m = mag.row(i).maxCoeff(&j);
		float gm = std::max((float)sqrt(m),1e-10f);
		g[i] = gm;
	}
}
template <int BINS>
static void computeGradHist( Image & hist, const RMatrixXf & gm, const RMatrixXf & go, int nori ) {
	const int W = gm.cols(), H = gm.rows();
	const int Wb = W/BINS, Hb = H/BINS;
	const int W0 = Wb*BINS, H0 = Hb*BINS;
	hist.create( Wb, Hb, nori );
	hist = 0;
	int *o0 = (int*)_mm_malloc( (W+4)*sizeof(int), 16 ), *o1 = (int*)_mm_malloc( (W+4)*sizeof(int), 16 );
	float *v0 = (float*)_mm_malloc( (W+4)*sizeof(float), 16 ), *v1 = (float*)_mm_malloc( (W+4)*sizeof(float), 16 );
	for(int j = 0; j < H0; j++){
		float * phist = hist.data() + (j/BINS)*Wb*nori;
		const float * pgm = gm.data()+j*W;
		const float * pgo = go.data()+j*W;
		// Compute the bins for the entire row
		int i=0;
		for( ; i+3<W; i+=4 ) {
			__m128 o = _mm_loadu_ps( pgo+i ) * _mm_set1_ps(nori / M_PI);
			
			*(__m128i*)(o0+i) = _mm_cvttps_epi32( o );
			__m128 w = o - _mm_cvtepi32_ps( *(__m128i*)(o0+i) );
			
// 			if( o0[i] >= nori ) o0[i] = 0;
			*(__m128i*)(o0+i) = _mm_and_si128( *(__m128i*)(o0+i), _mm_cmplt_epi32( *(__m128i*)(o0+i), _mm_set1_epi32(nori) ) );
			
// 			o1[i] = o0[i]+1;
			*(__m128i*)(o1+i) = *(__m128i*)(o0+i) + _mm_set1_epi32(1);
// 			if( o1[i] >= nori ) o1[i] = 0;
			*(__m128i*)(o1+i) = _mm_and_si128( *(__m128i*)(o1+i), _mm_cmplt_epi32( *(__m128i*)(o1+i), _mm_set1_epi32(nori) ) );
			
			__m128 v = _mm_loadu_ps( pgm+i ) * _mm_set1_ps( 1.0 / (BINS*BINS) );
			*(__m128*)(v0+i) = (_mm_set1_ps(1.f)-w)*v;
			*(__m128*)(v1+i) = w*v;
		}
		for( ; i<W; i++ ) {
			float o = pgo[i] / M_PI * nori;
			
			o0[i] = o;
			float w = o - o0[i];
			if( o0[i] >= nori ) o0[i] = 0;
			
			o1[i] = o0[i]+1;
			if( o1[i] >= nori ) o1[i] = 0;
			
			v0[i] = (1-w)*pgm[i] / (BINS*BINS);
			v1[i] = w*pgm[i] / (BINS*BINS);
		}
		
		// Add the bin
		for(int i = 0; i < W0; phist+=nori){
			for(int k = 0; k < BINS && i<W; i++, k++){
				phist[o0[i]] += v0[i];
				phist[o1[i]] += v1[i];
			}
		}
	}
	_mm_free( o0 );
	_mm_free( o1 );
	_mm_free( v0 );
	_mm_free( v1 );
}
void gradientHist( Image & hist, const RMatrixXf & gm, const RMatrixXf & go, int nori, int nbins) {
	switch(nbins){
		case 1: return computeGradHist<1>(hist, gm, go, nori);
		case 2: return computeGradHist<2>(hist, gm, go, nori);
		case 3: return computeGradHist<3>(hist, gm, go, nori);
		case 4: return computeGradHist<4>(hist, gm, go, nori);
		case 5: return computeGradHist<5>(hist, gm, go, nori);
		case 6: return computeGradHist<6>(hist, gm, go, nori);
		case 7: return computeGradHist<7>(hist, gm, go, nori);
		case 8: return computeGradHist<8>(hist, gm, go, nori);
		default: throw std::invalid_argument("Bin size too large!");
	}
}

void diff( float * dx, const float * x0, const float * x1, int N, float w ) {
	__m128 ww = _mm_set1_ps(w);
	int i=0;
	for( ; i+3<N; i+=4 )
		_mm_storeu_ps( dx+i, ww*(_mm_loadu_ps(x1+i)-_mm_loadu_ps(x0+i)) );
	for( ; i<N; i++ )
		dx[i] = w*(x1[i]-x0[i]);
}
void gradx( float * dx, const float * x, int N, int C ) {
	for( int c=0; c<C; c++ )
		dx[c] = x[C+c]-x[c];
	diff( dx+C, x, x+2*C, (N-2)*C, 0.5 );
	for( int c=0; c<C; c++ )
		dx[(N-1)*C+c] = x[(N-1)*C+c]-x[(N-2)*C+c];
}
void gradientMagAndOri( RMatrixXf & gm, RMatrixXf & go, const Image & im, int norm_rad, float norm_const ) {
	const int W = im.W(), H = im.H(), C = im.C();
	go = RMatrixXf::Zero(H, W);
	gm = RMatrixXf::Zero(H, W);
	float * gx = (float*)_mm_malloc((W+4)*C*sizeof(float),16);
	float * gy = (float*)_mm_malloc((W+4)*C*sizeof(float),16);
	for( int j=0; j<H; j++ ) {
		const int j0 = j>0?j-1:j, j1 = j<H-1?j+1:j;
		gradx( gx, im.data()+j*W*C, W, C );
		diff( gy, im.data()+j0*W*C, im.data()+j1*W*C, W*C, 1.0 / (j1-j0) );
		computeGradientOriAndMag(gm.data()+j*W, go.data()+j*W, gx, gy, W, C);
	}
	_mm_free( gx );
	_mm_free( gy );
	if( norm_rad>0 ) {
		RMatrixXf tmp_m(H,W);
		float * tmp = tmp_m.data();
		tentFilter( tmp, gm.data(), W, H, 1, norm_rad );
		float * r = gm.data();
		int i=0;
		for( ; i+3<W*H; i+=4 )
			_mm_storeu_ps( r+i, _mm_loadu_ps(r+i)/(_mm_loadu_ps(tmp+i)+_mm_set1_ps(norm_const)) );
		for( ; i<W*H; i++ )
			r[i] /= tmp[i] + norm_const;
	}
}
RMatrixXf gradientMag( const Image & im, int norm_rad, float norm_const ) {
	const int W = im.W(), H = im.H(), C = im.C();
	RMatrixXf gm(H, W);

	float * gx = (float*)_mm_malloc((W+4)*C*sizeof(float),16);
	float * gy = (float*)_mm_malloc((W+4)*C*sizeof(float),16);
	for( int j=0; j<H; j++ ) {
		const int j0 = j>0?j-1:j, j1 = j<H-1?j+1:j;
		gradx( gx, im.data()+j*W*C, W, C );
		diff( gy, im.data()+j1*W*C, im.data()+j0*W*C, W*C, 1.0 / (j1-j0) );
		computeGradientMag(gm.data()+j*W,gx, gy, W, C);
	}
	_mm_free( gx );
	_mm_free( gy );
	
	if( norm_rad>0 ) {
		RMatrixXf tmp_m(H,W);
		float * tmp = tmp_m.data();
		tentFilter( tmp, gm.data(), W, H, 1, norm_rad );
		for( int i=0; i<W*H; i++ )
			gm.data()[i] /= tmp[i] + norm_const;
	}
	return gm;
}
