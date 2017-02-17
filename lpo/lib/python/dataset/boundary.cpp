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
#include "evaluation.h"
#include "util/util.h"
#include "util/eigen.h"
#include <imgproc/morph.h>
#include <tuple>
#include <queue>
#include <stack>
#include <cmath>
#include "python/util.h"

namespace EvalPrivate {
struct BipartiteMatch {
private:
	bool bfs( int na, const std::vector< std::vector<int> > & nbr, std::vector<float> & dist ) {
		const float inf = std::numeric_limits<float>::infinity();
		std::queue<int> q;
		dist[0] = inf;
		for( int v=0; v <na; v++ ) {
			if( match_a[v]==-1 ) {
				dist[v+1] = 0;
				q.push( v );
			} else
				dist[v+1] = inf;
		}
		while( !q.empty() ) {
			int v = q.front();
			q.pop();
			if (dist[v+1] < dist[0])
				for( int u: nbr[v] )
					if (dist[ match_b[u]+1 ] == inf) {
						dist[ match_b[u]+1 ] = dist[v+1] + 1;
						q.push( match_b[u] );
					}
		}
		return dist[0] < inf;
	}
	bool dfs( int v, const std::vector< std::vector<int> > & nbr, std::vector<float> & dist ) {
		const float inf = std::numeric_limits<float>::infinity();
		if( v>=0 ) {
			if( dist[v+1] == inf )
				return false;

			for( int u: nbr[v] ) {
				if( dist[ match_b[u]+1 ] == dist[v+1] + 1 && dfs( match_b[u], nbr, dist ) ) {
					match_b[u] = v;
					match_a[v] = u;
					return true;
				}
			}
			dist[v+1] = inf;
			return false;
		}
		return true;
	}
public:
	struct Edge {
		int a,b;
		Edge( int a=0, int b=0 ):a(a),b(b) {}
	};
	std::vector< int > match_a, match_b;
	BipartiteMatch( int na, int nb, const std::vector< Edge > & edges ):match_a( na, -1 ), match_b( nb, -1 ) {
		// 		const float inf = std::numeric_limits<float>::infinity();
		// Build the graph
		std::vector< std::vector<int> > nbr( na );
		for( Edge e: edges )
			nbr[e.a].push_back( e.b );

		// Run Hopcroft-Karp
		std::vector<float> dist( na+1, 0 );
		while(1) {
			// Run BFS
			if( !bfs( na, nbr, dist ) )
				break;

			// Start matching
			for( int i=0; i<na; i++ )
				if( match_a[i] == -1 ) {
					// Run a DFS
					dfs( i, nbr, dist );
				}
		}
	}
};
}
//void matchAny( bool * pr, const bool * pa, const bool * pb, int W, int H, double max_r ) {
//	memset( pr, 0, W*H*2*sizeof(bool) );
//	float r2 = max_r*max_r*(W*W+H*H);
//    const int rd = (int) ceil(sqrt(r2));
//	for( int j=0; j<H; j++ )
//		for( int i=0; i<W; i++ )
//			if( pa[j*W+i] )
//				for( int jj=std::max(j-rd,0); jj<=std::min(j+rd,H-1); jj++ )
//					for( int ii=std::max(i-rd,0); ii<=std::min(i+rd,W-1); ii++ )
//						if( (i-ii)*(i-ii)+(j-jj)*(j-jj) <= r2 )
//							if( pb[jj*W+ii] )
//								pr[j*W+i+0*W*H] = pr[jj*W+ii+1*W*H] = 1;
//}
//np::ndarray matchAny(const np::ndarray & a, const np::ndarray & b, double max_r ) {
//	checkArray( a, bool, 2, 2, true );
//	checkArray( b, bool, 2, 2, true );
//	int H = a.shape(0), W = a.shape(1);
//	if( H != b.shape(0) || W != b.shape(1) )
//		throw std::invalid_argument( "a and b need to have the same shape!\n" );
//	np::ndarray r = np::zeros( make_tuple(2,H,W), a.get_dtype() );
//	matchAny( (bool *)r.get_data(), (const bool *)a.get_data(), (const bool *)b.get_data(), W, H, max_r );
//	return r;
//}

std::tuple<RMatrixXb,RMatrixXb> matchAny( const RMatrixXb & a, const RMatrixXb & b, double max_r ) {
	const int W = a.cols(), H = a.rows();
	eassert( W == b.cols() && H == b.rows() );
	RMatrixXb ma = RMatrixXb::Zero( H, W ), mb = RMatrixXb::Zero( H, W );

	float r2 = max_r*max_r*(W*W+H*H);
	const int rd = (int) ceil(sqrt(r2));
	for( int j=0; j<H; j++ )
		for( int i=0; i<W; i++ )
			if( a(j,i) )
				for( int jj=std::max(j-rd,0); jj<=std::min(j+rd,H-1); jj++ )
					for( int ii=std::max(i-rd,0); ii<=std::min(i+rd,W-1); ii++ )
						if( (i-ii)*(i-ii)+(j-jj)*(j-jj) <= r2 )
							if( b(jj,ii) )
								ma(j,i) = mb(jj,ii) = 1;
	return std::make_tuple( ma, mb );
}
std::tuple<RMatrixXb,RMatrixXb> matchBp( const RMatrixXb & a, const RMatrixXb & b, double max_r ) {
	using namespace EvalPrivate;
	const int W = a.cols(), H = a.rows();
	eassert( W == b.cols() && H == b.rows() );
	RMatrixXb ma, mb;

	std::tie(ma,mb) = matchAny( a, b, max_r );

	float r2 = max_r*max_r*(W*W+H*H);
	const int rd = (int) ceil(sqrt(r2));
	// Compute the bipartite graph size
	std::vector<int> ia(W*H,-1), ib(W*H,-1);
	int ca=0,cb=0;
	for( int j=0; j<H; j++ )
		for( int i=0; i<W; i++ ) {
			if( ma(j,i) )
				ia[j*W+i] = ca++;
			if( mb(j,i) )
				ib[j*W+i] = cb++;
		}

	std::vector< BipartiteMatch::Edge > edges;
	for( int j=0; j<H; j++ )
		for( int i=0; i<W; i++ )
			if( ia[j*W+i]>=0 )
				for( int jj=std::max(j-rd,0); jj<=std::min(j+rd,H-1); jj++ )
					for( int ii=std::max(i-rd,0); ii<=std::min(i+rd,W-1); ii++ )
						if( (i-ii)*(i-ii)+(j-jj)*(j-jj) <= r2 )
							if( ib[jj*W+ii]>=0 )
								edges.push_back( BipartiteMatch::Edge(ia[j*W+i],ib[jj*W+ii]) );

	BipartiteMatch match( ca, cb, edges );
	for( int j=0; j<H; j++ )
		for( int i=0; i<W; i++ ) {
			if( ia[j*W+i]>=0 )
				ma(j,i) = (match.match_a[ ia[j*W+i] ]>=0);
			if( ib[j*W+i]>=0 )
				mb(j,i) = (match.match_b[ ib[j*W+i] ]>=0);
		}
	return std::make_tuple(ma, mb);
}
//void matchBp( bool * pr, const bool * pa, const bool * pb, int W, int H, double max_r ) {
//	using namespace EvalPrivate;
//	matchAny( pr, pa, pb, W, H, max_r );
//	float r2 = max_r*max_r*(W*W+H*H);
//    const int rd = (int) ceil(sqrt(r2));
//	// Compute the bipartite graph size
//	std::vector<int> ia(W*H,-1), ib(W*H,-1);
//	int ca=0,cb=0;
//	for( int j=0; j<H; j++ )
//		for( int i=0; i<W; i++ ) {
//			if( pr[j*W+i+0] )
//				ia[j*W+i] = ca++;
//			if( pr[j*W+i+W*H] )
//				ib[j*W+i] = cb++;
//		}
//
//	std::vector< BipartiteMatch::Edge > edges;
//	for( int j=0; j<H; j++ )
//		for( int i=0; i<W; i++ )
//			if( ia[j*W+i]>=0 )
//				for( int jj=std::max(j-rd,0); jj<=std::min(j+rd,H-1); jj++ )
//					for( int ii=std::max(i-rd,0); ii<=std::min(i+rd,W-1); ii++ )
//						if( (i-ii)*(i-ii)+(j-jj)*(j-jj) <= r2 )
//							if( ib[jj*W+ii]>=0 )
//								edges.push_back( BipartiteMatch::Edge(ia[j*W+i],ib[jj*W+ii]) );
//
//	BipartiteMatch match( ca, cb, edges );
//	for( int j=0; j<H; j++ )
//		for( int i=0; i<W; i++ ) {
//			if( ia[j*W+i]>=0 )
//				pr[j*W+i+0]   = (match.match_a[ ia[j*W+i] ]>=0);
//			if( ib[j*W+i]>=0 )
//				pr[j*W+i+W*H] = (match.match_b[ ib[j*W+i] ]>=0);
//		}
//}
//np::ndarray matchBp(const np::ndarray & a, const np::ndarray & b, double max_r ) {
//	checkArray( a, bool, 2, 2, true );
//	checkArray( b, bool, 2, 2, true );
//	int H = a.shape(0), W = a.shape(1);
//	if( H != b.shape(0) || W != b.shape(1) )
//		throw std::invalid_argument( "a and b need to have the same shape!\n" );
//	np::ndarray r = np::zeros( make_tuple(2,H,W), a.get_dtype() );
//	matchBp( (bool*)r.get_data(), (const bool*)a.get_data(), (const bool*)b.get_data(), W, H, max_r );
//	return r;
//}
Vector4i evalBoundaryBinary( const RMatrixXb & d, const std::vector<RMatrixXb> & bnd, double max_r, const RMatrixXb & mask ) {
	const int W = d.cols(), H = d.rows(), D = bnd.size();
	eassert( mask.cols() == W && mask.rows() == H );

	int sum_r=0, cnt_r=0;
	RMatrixXb ma, mb, acc = RMatrixXb::Zero(H,W);
	for( int k=0; k<D; k++ ) {
		eassert( W == bnd[k].cols() && H == bnd[k].rows() );

		std::tie(ma,mb) = matchBp( d, bnd[k], max_r );

		acc = acc.array() || (ma.array() && mask.array());
		sum_r += (bnd[k].array() && mask.array()).cast<int>().sum();
		cnt_r += (mb.array() && mask.array()).cast<int>().sum();
	}
	int sum_p = (d.array() && mask.array()).cast<int>().sum();
	int cnt_p = (acc.array() && mask.array()).cast<int>().sum();
	return Vector4i(cnt_r,sum_r,cnt_p,sum_p);
}
Vector4i evalBoundaryBinary( const RMatrixXb & d, const std::vector<RMatrixXb> & bnd, double max_r ) {
	return evalBoundaryBinary( d, bnd, max_r, RMatrixXb::Ones(d.rows(),d.cols()) );
}
RMatrixXf evalBoundary( const RMatrixXf & d, const std::vector<RMatrixXb> & bnd, int nthres, double max_r, const RMatrixXb & mask ) {
	RMatrixXf r( nthres, 5 );
	for( int i=0; i<nthres; i++ ) {
		float t = 1.0 * i / nthres;
		r(i,0) = t;
		RMatrixXb tmp = d.array() > t;
		if ( t > 0 )
			thinningGuoHall( tmp );
		r.block(i,1,1,4) = evalBoundaryBinary( tmp, bnd, max_r, mask ).cast<float>().transpose();
	}
	return r;
}
RMatrixXf evalBoundary( const RMatrixXf & d, const std::vector<RMatrixXb> & bnd, int nthres, double max_r ) {
	return evalBoundary( d, bnd, nthres, max_r, RMatrixXb::Ones(d.rows(),d.cols()) );
}

std::vector<RMatrixXf> evalBoundaryAll( const std::vector<RMatrixXf> &ds, const std::vector< std::vector<RMatrixXb> > &bnds, int nthres, double max_r ) {
	eassert( ds.size() == bnds.size() );
	const int N = ds.size();

	std::vector<RMatrixXf> res( N );
	#pragma omp parallel for ordered schedule(dynamic)
	for( int i=0; i<N; i++ )
		res[i] = evalBoundary( ds[i], bnds[i], nthres, max_r );
	return res;
}

std::vector<RMatrixXf> evalSegmentBoundaryAll( const std::vector<RMatrixXf> &ds, const std::vector<RMatrixXs> &segs, int nthres, double max_r ) {
	eassert( ds.size() == segs.size() );
	const int N = ds.size();

	std::vector<RMatrixXf> res( N );
	#pragma omp parallel for ordered schedule(dynamic)
	for( int i=0; i<N; i++ ) {
		const int W = segs[i].cols(), H = segs[i].rows();
		RMatrixXb mask = RMatrixXb::Ones( H, W ), bnd = RMatrixXb::Zero( H, W );
		for( int r=0; r<H; r++ )
			for( int c=0; c<W; c++ ) {
				mask(r,c) = segs[i](r,c) >= 0;
				if( c && segs[i](r,c) != segs[i](r,c-1) )
					bnd(r,c) = bnd(r,c-1) = 1;
				if( r && segs[i](r,c) != segs[i](r-1,c) )
					bnd(r,c) = bnd(r-1,c) = 1;
			}
		const float r2 = max_r*max_r*(W*W+H*H);
		const int sr = sqrt(r2);
		for( int r=0; r<H; r++ )
			for( int c=0; c<W; c++ )
				if( bnd(r,c) ) {
					for( int rr=std::max(-r,-sr); rr<=sr && r+rr < H; rr++ )
						for( int cc=std::max(-c,-sr); cc<=sr && c+cc < W; cc++ )
							if( rr*rr+cc*cc <= r2 )
								mask(r+rr,c+cc) = 1;
				}

		thinningGuoHall( bnd );

		res[i] = evalBoundary( ds[i], std::vector<RMatrixXb>(1,bnd), nthres, max_r, mask );
	}

	return res;
}
