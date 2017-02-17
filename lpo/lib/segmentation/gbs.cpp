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
#include "gbs.h"
#include "util/algorithm.h"
#include <algorithm>

#define USE_BIN_SORT

RMatrixXs gbs( const Image & im, float c, int min_size ) {
	return GBS(im).compute(c,min_size);
}
GBS::GBS(const Image& im):W_(im.W()),H_(im.H()) {
	const int N = im.W()*im.H();
	std::vector<Event> q;
	q.reserve( N*4 );
	for( int j=0,k=0; j<im.H(); j++ )
		for( int i=0; i<im.W(); i++,k++ ) {
			if( i )
				q.push_back( Event( (im.at<3>(j,i)-im.at<3>(j,i-1)).norm(), k, k-1 ) );
			if( j )
				q.push_back( Event( (im.at<3>(j,i)-im.at<3>(j-1,i)).norm(), k, k-im.W() ) );
// 			if( i && j )
// 				q.push_back( Event( (im.at<3>(j,i)-im.at<3>(j-1,i-1)).norm(), k, k-1-im.W() ) );
// 			if( i && j<im.H()-1 )
// 				q.push_back( Event( (im.at<3>(j,i)-im.at<3>(j+1,i-1)).norm(), k, k+im.W()-1 ) );
		}
#ifdef USE_BIN_SORT
	const int N_BIN = 2048;
	float m = 0;
	for( const Event & e: q )
		m = std::max(m,e.w);
	m = (N_BIN-1) / (m+1e-10);
	std::vector<int> bin_id( N_BIN, 0 );
	for( const Event & e: q )
		bin_id[ m*e.w ] += 1;
	for( int i=1; i<N_BIN; i++ )
		bin_id[ i ] += bin_id[i-1];
	q_.resize( q.size() );
	for( const Event & e: q )
		q_[ --bin_id[ m*e.w ] ] = e;
#else
	std::sort( q.begin(), q.end() );
	q_ = q;
#endif
}
RMatrixXs GBS::compute(float c, int min_size) const {
	UnionFindSet uf( W_*H_ );
	VectorXi size = VectorXi::Ones( W_*H_ );
	VectorXf t = VectorXf::Constant( W_*H_, c );
	for( const Event & e: q_ ) {
		int a = uf.find(e.a), b = uf.find(e.b);
		if( a!=b && e.w<=t[a] && e.w<=t[b] ) {
			int m = uf.merge(a, b);
			size[m] = size[a]+size[b];
			t[m] = e.w + c/size[m];
		}
	}
	// Merge small components
	for( const Event & e: q_ ) {
		int a = uf.find(e.a), b = uf.find(e.b);
		if( a!=b && (size[a] < min_size || size[b] < min_size ) ) {
			int m = uf.merge(a, b);
			size[m] = size[a]+size[b];
		}
	}

	int tot_size = 0;
	RMatrixXs r( H_, W_ );
	VectorXi unique_id = -VectorXi::Ones( W_*H_ );
	for( int j=0,k=0,n=0; j<H_; j++ )
		for( int i=0; i<W_; i++,k++ ) {
			int id = uf.find(k);
			if( unique_id[id] == -1 ) {
				unique_id[id] = n++;
				tot_size += size[id];
			}
			r(j,i) = unique_id[id];
		}
	return r;
}
