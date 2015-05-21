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
#include "proposal.h"
#include "util/util.h"
#include "segmentation/iouset.h"
#include "segmentation/segmentation.h"
#include <iostream>
#include <random>

Proposals::Proposals() {
}
Proposals::Proposals(const RMatrixXs& s, const RMatrixXb& p) : s(s), p(p) {
}
void Proposals::load(std::istream& is) {
	loadMatrixX(is,s);
	loadMatrixX(is,p);
}
void Proposals::save(std::ostream& os) const {
	saveMatrixX(os,s);
	saveMatrixX(os,p);
}
bool Proposals::operator==(const Proposals& o) const {
	return s == o.s && p == o.p;
}
RMatrixXi Proposals::toBoxes() const{
	return maskToBox( s, p );
}

static VectorXs map_id( const RMatrixXi & ms, const RMatrixXs & s ) {
	eassert( ms.rows() == s.rows() && ms.cols() == s.cols() );
	int Nms = ms.maxCoeff()+1;
	VectorXs r = VectorXs::Zero(Nms);
	for( int j=0; j<s.rows(); j++ )
		for( int i=0; i<s.cols(); i++ )
			r[ ms(j,i) ] = s(j,i);
	return r;
}

std::vector<Proposals> nms( const std::vector<Proposals> & proposals, const std::vector<int> & order, float max_iou ) {
	int N = 0;
	for( const Proposals & p: proposals )
		N += p.p.rows();
	std::vector<int> s_id( N ), p_id( N );
	for( int i=0, k=0; i<proposals.size(); i++ )
		for( int j=0; j<proposals[i].p.rows(); j++, k++ ) {
			s_id[k] = i;
			p_id[k] = j;
		}

	std::vector<RMatrixXs> s;
	std::vector<int> Ns;
	for( int i=0; i<proposals.size(); i++ ) {
		s.push_back( proposals[i].s );
		Ns.push_back( proposals[i].s.maxCoeff()+1 );
	}
	const RMatrixXi ms = mergeOverSegmentations(s);
	const int Nms = ms.maxCoeff()+1;
	
	VectorXu ms_area = VectorXu::Zero( Nms );
	for( int j=0; j<ms.rows(); j++ )
		for( int i=0; i<ms.cols(); i++ )
			ms_area[ ms(j,i) ]++;
	
	std::vector<IOUSet> iou_set;
	std::vector<VectorXs> ids;
	for( int i=0; i<s.size(); i++ ) {
		iou_set.push_back( s[i] );
		ids.push_back( map_id( ms, s[i] ) );
	}
	
	std::vector<int> pb;
	pb.reserve( Nms );
	
	std::vector< std::vector< VectorXb > > r( proposals.size() );
	for( int i: order ) {
		VectorXb p = proposals[ s_id[i] ].p.row( p_id[i] );
		// Run NMS
		if( !p.any() || iou_set[ s_id[i] ].intersects(p,max_iou) )
			continue;
		
		Vector4s bbox = iou_set[ s_id[i] ].computeBBox( p );
		
		// Project each segmentation onto the common OS
		pb.clear();
		for( int j=0; j<Nms; j++ )
			if( p[ ids[ s_id[i] ][j] ] )
				pb.push_back( j );
		
		bool intersects = false;
		for( int k=0; !intersects && k<iou_set.size(); k++ ) 
			if( s_id[i] != k ){
				// Reproject the common OS to the current os
				VectorXu p_area = VectorXu::Zero( Ns[k] );
				for( int j: pb )
					p_area[ ids[ k ][j] ] += ms_area[ j ];
				// Run more NMS
				intersects = iou_set[k].intersects(p_area, bbox, max_iou);
			}
		if( !intersects ) {
			// Add the segment
			iou_set[ s_id[i] ].add( p );
			r[ s_id[i] ].push_back( p );
		}
	}
	
	
	std::vector<Proposals> res( proposals.size() );
	for( int i=0; i<proposals.size(); i++ ) {
		res[i].s = proposals[i].s;
		res[i].p = RMatrixXb( r[i].size(), proposals[i].p.cols() );
		for( int j=0; j<r[i].size(); j++ )
			res[i].p.row(j) = r[i][j];
	}
	return res;
}

std::vector<Proposals> nms( const std::vector<Proposals> & proposals, float max_iou ) {
	std::mt19937 rand;
	int N = 0;
	for( const Proposals & p: proposals )
		N += p.p.rows();
	std::vector<int> order( N );
	for( int i=0; i<N; i++ ) {
		order[i] = i;
		std::swap( order[i], order[rand()%(i+1)] );
	}
	return nms( proposals, order, max_iou );
}
std::vector<Proposals> boxNms( const std::vector<Proposals> & proposals, const std::vector<int> & order, float max_iou, float min_box_size ) {
	std::multimap<float,int> area_map;
	area_map.insert(std::make_pair(0.f,-1));
	area_map.insert(std::make_pair(1e6f,-1));
	
	std::vector<Vector4i> boxes;
	for( const Proposals & p: proposals ) {
		RMatrixXi b = maskToBox( p.s, p.p );
		for( int i=0; i<b.rows(); i++ )
			boxes.push_back( b.row(i) );
	}
	
	std::vector<bool> is_good( boxes.size() );
	for( int i: order ) {
		Vector4i b = boxes[i];
		float ba = boxArea(b);
		if (min_box_size > ba)
			continue;
		
		bool overlaps = false;
		auto i0 = area_map.upper_bound(ba);
		auto i1 = i0--;
		while(!overlaps) {
			if( i1->second >= 0 && ba*ba > i1->first*i0->first && ba > max_iou*i1->first ) {
				overlaps = boxIou(boxes[i1->second],b) >= max_iou;
				++i1;
			}
			else if( i0->second >= 0 && ba * max_iou < i0->first ) {
				overlaps = boxIou(boxes[i0->second],b) >= max_iou;
				--i0;
			}
			else
				break;
		}
		is_good[i] = !overlaps;
		if( !overlaps )
			area_map.insert( std::make_pair(ba,i) );
	}
	std::vector<Proposals> res( proposals.size() );
	for( int i=0,k=0; i<proposals.size(); i++ ) {
		res[i].s = proposals[i].s;
		std::vector<RowVectorXb> good_p;
		for( int j=0; j<proposals[i].p.rows(); j++,k++ )
			if( is_good[k] )
				good_p.push_back( proposals[i].p.row(j) );
		
		res[i].p = RMatrixXb( good_p.size(), proposals[i].p.cols() );
		for( int j=0; j<good_p.size(); j++ )
			res[i].p.row(j) = good_p[j];
	}
	return res;
}

std::vector<Proposals> boxNms( const std::vector<Proposals> & proposals, float max_iou, float min_box_size ) {
	std::mt19937 rand;
	int N = 0;
	for( const Proposals & p: proposals )
		N += p.p.rows();
	std::vector<int> order( N );
	for( int i=0; i<N; i++ ) {
		order[i] = i;
		std::swap( order[i], order[rand()%(i+1)] );
	}
	return boxNms( proposals, order, max_iou, min_box_size );
}

Proposals nms( const Proposals & proposals, const std::vector<int> & order, float max_iou ) {
	IOUSet iou_set( proposals.s );
	
	std::vector< VectorXb > r;
	for( int i: order ) {
		VectorXb p = proposals.p.row( i );
		// Run NMS
		if( p.any() && iou_set.addIfNotIntersects(p,max_iou) )
			r.push_back( p );
	}
	
	Proposals res;
	res.s = proposals.s;
	res.p = RMatrixXb( r.size(), proposals.p.cols() );
	for( int j=0; j<r.size(); j++ )
		res.p.row(j) = r[j];
	return res;
}

Proposals nms( const Proposals & proposals, float max_iou ) {
	std::mt19937 rand;
	int N = proposals.p.rows();
	std::vector<int> order( N );
	for( int i=0; i<N; i++ ) {
		order[i] = i;
		std::swap( order[i], order[rand()%(i+1)] );
	}
	return nms( proposals, order, max_iou );
}
