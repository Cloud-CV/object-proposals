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
#include "iouset.h"
#include "segmentation.h"
#include <queue>

IOUSet::IOUSet( const RMatrixXs &s ) {
	init( s );
	area_map_.insert( std::make_pair( (unsigned int)0, (short)-1 ) );
	area_map_.insert( std::make_pair( (unsigned int)s.size()+1, (short)-1 ) );
}
IOUSet::IOUSet( const ImageOverSegmentation &os ) {
	init( os.s() );
	area_map_.insert( std::make_pair( (unsigned int)0, (short)-1 ) );
	area_map_.insert( std::make_pair( (unsigned int)os.s().size()+1, (short)-1 ) );
}

void IOUSet::init(const RMatrixXs &s ) {
	const int N = s.maxCoeff()+1;
	// Compute the x and y position and id
	std::vector< Vector3f > pos( N, Vector3f::Zero() );
	spix_box_.resize( N, Vector4s(s.cols(),s.rows(),0,0) );
	for( int j=0; j<s.rows(); j++ )
		for( int i=0; i<s.cols(); i++ ) {
			pos[ s(j,i) ] += Vector3f( i, j, 1 );
			if (spix_box_[ s(j,i) ][0] > i) spix_box_[ s(j,i) ][0] = i;
			if (spix_box_[ s(j,i) ][1] > j) spix_box_[ s(j,i) ][1] = j;
			if (spix_box_[ s(j,i) ][2] <=i) spix_box_[ s(j,i) ][2] = i+1;
			if (spix_box_[ s(j,i) ][3] <=j) spix_box_[ s(j,i) ][3] = j+1;
		}
	area_.resize( N );
	for( int i=0; i<N; i++ ) {
		area_[i] = pos[i][2];
		pos[i] /= pos[i][2] + 1e-10;
		pos[i][2] = i;
	}
	// Compute the kd-tree
	std::queue< std::tuple<int,int,int> > q;
	q.push( std::make_tuple( 0, N, -1 ) );

	int nid = 2*N-1;
	parent_.resize( nid, -1 );
	left_.resize( nid, -1 );
	right_.resize( nid, -1 );
	while( !q.empty() ) {
		int a, b, pid;
		std::tie(a,b,pid) = q.front();
		q.pop();

		// Leaf node
		if( a+1>=b ) {
			parent_[pos[a][2]] = pid;
			if( left_[pid] == -1 )
				left_[pid] = pos[a][2];
			else if( right_[pid] == -1 )
				right_[pid] = pos[a][2];
		} else {
			// Build the graph [add the node]
			int id = --nid;
			if( id < N )
				printf("EVIL %d < %d!  [%d %d %d]\n", id, N, a, b, pid);
			parent_[id] = pid;
			if( pid >=0 && left_[pid] == -1 )
				left_[pid] = id;
			else if( pid >=0 && right_[pid] == -1 )
				right_[pid] = id;

			// Find a split point [x or y]
			int best_d = 0;
			float dist = 0, split=0;
			for( int d=0; d<2; d++ ) {
				float x0 = pos[a][d], x1 = pos[a][d];
				float sx = 0, ct = 0;
				for( int i=a; i<b; i++ ) {
					x0 = std::min( x0, pos[i][d] );
					x1 = std::max( x1, pos[i][d] );
					sx += pos[i][d];
					ct += 1;
				}
				if (x1-x0 >= dist) {
					dist = x1-x0;
					split = sx / ct;
					best_d = d;
				}
			}
			// Split
			int s = a, e = b-1;
			while( s<e ) {
				while( s < b && pos[s][best_d] < split ) s++;
				while( e >= a && pos[e][best_d] >= split ) e--;
				if( s<e )
					std::swap( pos[s], pos[e] );
			}
			if( s==a )
				s++;
			// Add to q
			q.push( std::make_tuple(a,s,id) );
			q.push( std::make_tuple(s,b,id) );
		}
	}
	area_.conservativeResize( 2*N-1 );
	area_.tail(N-1).setZero();
	for( int i=0; i<2*N-1; i++ )
		if( parent_[i] >= 0 )
			area_[parent_[i]] += area_[i];
}
VectorXu IOUSet::sumTree(const VectorXu & s) const {
	VectorXu r = VectorXu::Zero(parent_.size());
	r.head(s.size()) = s;
	for( int i=0; i<r.size(); i++ )
		if( parent_[i] >= 0 )
			r[ parent_[i] ] += r[i];
	return r;
}
VectorXu IOUSet::computeTree(const VectorXb & s) const {
	return sumTree( area_.head(s.size()).array()*s.cast<unsigned int>().array() );
}
Vector4s IOUSet::computeBBox( const VectorXb & v ) const {
	Vector4s box(1<<14,1<<14,0,0);
	for( int i=0; i<spix_box_.size(); i++ )
		if( v[i] ) {
			if( box[0] > spix_box_[i][0] ) box[0] = spix_box_[i][0];
			if( box[1] > spix_box_[i][1] ) box[1] = spix_box_[i][1];
			if( box[2] < spix_box_[i][2] ) box[2] = spix_box_[i][2];
			if( box[3] < spix_box_[i][3] ) box[3] = spix_box_[i][3];
		}
	return box;
}
void IOUSet::addTree(const VectorXu &v) {
	area_map_.insert( std::make_pair( v[v.size()-1], (short)set_.size() ) );
	set_.push_back( v );
	// Add the bounding box for fast rejection
	if( spix_box_.size() )
		bbox_.push_back( computeBBox( v.array()>0 ) );
}
static float boxIOUBound( const Vector4s & b0, const Vector4s & b1, float a0, float a1 ) {
	float max_o = boxOverlap( b0.cast<int>(), b1.cast<int>() );
	return max_o / std::max( max_o, a0+a1-max_o );
}
bool IOUSet::intersectsTree(const VectorXu &v, const Vector4s & bbox, float max_iou) const {
	const unsigned int area = v[v.size()-1];
	auto i0 = area_map_.lower_bound( area );
	auto i1 = i0--;

#define IOU_BOUND( it ) ((it)->second==-1?0:((float)std::min(area,(it)->first)/(float)std::max(area,(it)->first)))
	float iou0 = IOU_BOUND( i0 ), iou1 = IOU_BOUND( i1 );
	while (iou0 >= max_iou || iou1 >= max_iou ) {
		if( iou0 < iou1 ) {
			if( ( spix_box_.size()==0 || boxIOUBound( bbox, bbox_[i1->second], area, set_[i1->second][v.size()-1] ) >= max_iou ) && cmpIOU(v,set_[i1->second],max_iou) )
				return true;
			i1++;
			iou1 = IOU_BOUND(i1);
		} else {
			if( ( spix_box_.size()==0 || boxIOUBound( bbox, bbox_[i0->second], area, set_[i0->second][v.size()-1] ) >= max_iou ) && cmpIOU(v,set_[i0->second],max_iou) )
				return true;
			i0--;
			iou0 = IOU_BOUND(i0);
		}
	}
	return false;
}
bool IOUSet::intersectsTree(const VectorXu &v, float max_iou) const {
	return intersectsTree( v, computeBBox( v.array()>0 ), max_iou );
}
void IOUSet::add(const VectorXb &s) {
	addTree( computeTree( s ) );
}
bool IOUSet::intersects(const VectorXb &s, float max_iou) const {
	return intersectsTree( computeTree(s), max_iou );
}
bool IOUSet::intersects(const VectorXu &area, const Vector4s & bbox, float max_iou) const {
	return intersectsTree( sumTree(area), bbox, max_iou );
}
bool IOUSet::addIfNotIntersects( const VectorXb & p, float max_iou ) {
	VectorXu t = computeTree( p );
	if( intersectsTree( t, max_iou ) )
		return false;
	addTree( t );
	return true;
}

bool IOUSet::cmpIOU(const VectorXu &a, const VectorXu &b, float max_iou) const {
	assert( a.size() == b.size() );
	const int N = a.size();
	const float t = max_iou / (1 + max_iou);
	const float t_inter = t*(a[N-1]+b[N-1]);

	int upper = std::min(a[N-1], b[N-1]), lower = std::max((int)a[N-1]+(int)b[N-1]-(int)area_[N-1],0);
	if( lower >= t_inter ) return true;
	if( upper <= t_inter ) return false;
	std::queue<int> q;
	q.push( N-1 );
#define LOWER_BOUND(n) (std::max((int)(a[n])+(int)(b[n])-(int)(area_[n]),0))
#define UPPER_BOUND(n) (std::min((int)(a[n]),(int)(b[n])))
	while(!q.empty()) {
		int n = q.front();
		q.pop();
		// Split the current node
		int c_lower     = LOWER_BOUND(n)        , c_upper     = UPPER_BOUND(n);
		int left_lower  = LOWER_BOUND(left_[n]) , left_upper  = UPPER_BOUND(left_[n]);
		int right_lower = LOWER_BOUND(right_[n]), right_upper = UPPER_BOUND(right_[n]);
		lower += left_lower+right_lower-c_lower;
		upper += left_upper+right_upper-c_upper;
		if( lower >= t_inter ) return true;
		if( upper <= t_inter ) return false;
		if( left_lower < left_upper && left_[left_[n]] != -1 )
			q.push( left_[n] );
		if( right_lower < right_upper && right_[right_[n]] != -1 )
			q.push( right_[n] );
	}
	printf("l:%d  u:%d\n", lower, upper );
	return true;
}
