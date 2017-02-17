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
#include "dataset/apng.h"
#include "dataset/berkeley.h"
#include "dataset/coco.h"
#include "dataset/boundary.h"
#include "dataset/evaluation.h"
#include "dataset/nyu.h"
#include "dataset/voc.h"
#include "dataset/weizmann.h"
#include "lpo.h"
#include "util.h"
#include <segmentation/segmentation.h>
#include <proposals/proposal.h>
#include <util/algorithm.h>

tuple evaluateSegmentProposals1( const std::vector< std::vector< Proposals > > & props, const list & gt_segs ) {
	eassert( len(gt_segs) == props.size() );
	const int N = props.size();

	// Convert the Segment Data
	std::vector<RMatrixXs> gt_data(len(gt_segs));
	std::vector< std::vector<Polygons> > regions(len(gt_segs));
	bool has_regions = len( gt_segs )>0 && extract< std::vector<Polygons> >( gt_segs[0] ).check();
	for( int i=0; i<len(gt_segs); i++ ) {
		if( has_regions )
			regions[i] = extract< std::vector<Polygons> >( gt_segs[i] );
		else {
			gt_data[i] = extract<RMatrixXs>( gt_segs[i] );
		}
	}
	std::vector< VectorXf > bo(N), area(N);
	VectorXf pool_size(N);
	int n=0, box_n=0;
	#pragma omp parallel for
	for( int i=0; i<N; i++ ) {
		std::vector<Proposals> prop = props[i];
		bool first = true;
		for (const Proposals & p: prop ) {
			ProposalEvaluation peval = has_regions ? ProposalEvaluation( regions[i], p.s, p.p ) : ProposalEvaluation( gt_data[i].data(), gt_data[i].cols(), gt_data[i].rows(), 1, p.s, p.p );
			if( !bo[i].size() ) {
				bo[i] = peval.bo_;
				area[i] = peval.area_;
				pool_size[i] = peval.pool_size_;
			} else {
				bo[i] = bo[i].array().max( peval.bo_.array() );
				pool_size[i] += peval.pool_size_;
			}
			if( first )
				#pragma omp atomic
				n += peval.bo_.size();
			first = false;
		}
	}
	RMatrixXf r_bo = RMatrixXf::Zero( n, 2 );
	VectorXf r_b_bo = VectorXf::Zero( box_n );
	for( int i=0,k=0; i<N; i++ )
		for( int j=0; j<bo[i].size(); j++, k++ ) {
			r_bo(k,0) = bo[i][j];
			r_bo(k,1) = area[i][j];
		}
	return make_tuple( r_bo, pool_size );
}
tuple evaluateSegmentProposals2( const std::vector< Proposals > & props, const list & gt_segs ) {
	std::vector< std::vector< Proposals > > new_props( props.size() );
	for( int i=0; i<props.size(); i++ )
		new_props[i].push_back( props[i] );
	return evaluateSegmentProposals1( new_props, gt_segs );
}
tuple evaluateBoxProposals1( const std::vector< std::vector< Proposals > > & props, const list & gt_boxes ) {
	eassert( len(gt_boxes) == props.size() );
	const int N = props.size();

	// Convert the Segment Data
	std::vector<RMatrixXi> gt_box(len(gt_boxes));
	for( int i=0; i<len(gt_boxes); i++ )
		gt_box[i] = extract<RMatrixXi>( gt_boxes[i] );

	std::vector< VectorXf > bo(N);
	VectorXf pool_size(N);
	int n=0, box_n=0;
	#pragma omp parallel for
	for( int i=0; i<N; i++ ) {
		std::vector<Proposals> prop = props[i];
		bool first = true;
		for (const Proposals & p: prop ) {
			ProposalBoxEvaluation peval( gt_box[i], maskToBox(p.s,p.p) );
			if( !bo[i].size() ) {
				bo[i] = peval.bo_;
				pool_size[i] = peval.pool_size_;
			} else {
				bo[i] = bo[i].array().max( peval.bo_.array() );
				pool_size[i] += peval.pool_size_;
			}
			if( first )
				#pragma omp atomic
				n += peval.bo_.size();
			first = false;
		}
	}
	VectorXf r_bo = VectorXf::Zero( n );
	VectorXf r_b_bo = VectorXf::Zero( box_n );
	for( int i=0,k=0; i<N; i++ )
		for( int j=0; j<bo[i].size(); j++, k++ )
			r_bo[k] = bo[i][j];
	return make_tuple( r_bo, pool_size );
}
tuple evaluateBoxProposals2( const std::vector< Proposals > & props, const list & gt_boxes ) {
	std::vector< std::vector< Proposals > > new_props( props.size() );
	for( int i=0; i<props.size(); i++ )
		new_props[i].push_back( props[i] );
	return evaluateBoxProposals1( new_props, gt_boxes );
}
RMatrixXf overlapCOCO( const std::vector< Polygons > & segs, int bnd ) {
	int W=0,H=0;
	for( const auto & s: segs )
		for( const auto & p: s ) {
			H = std::max( (int)p.row(0).maxCoeff()+2+2*bnd, H );
			W = std::max( (int)p.row(1).maxCoeff()+2+2*bnd, W );
		}
	std::vector< std::vector<int> > seg_id(W*H);
	int id = 0;
	for( const auto & s: segs ) {
		rasterize( [&](int x, int y, RasterType t) {
			if(t!=OUTSIDE && 0<=x && x<W && 0<=y && y<H) seg_id[W*y+x].push_back( id );
		}, s, bnd );
		id++;
	}
	RMatrixXf overlap = RMatrixXf::Zero( segs.size(), segs.size() );
	for( const auto & s: seg_id ) {
		for( int a: s )
			for( int b: s )
				overlap(a,b) += 1;
	}
	return overlap;
}
class EmptyDirs {};
BOOST_PYTHON_FUNCTION_OVERLOADS( loadWeizmann_overload, loadWeizmann, 2, 3 )

void defineDataset() {
	ADD_MODULE(dataset);
	def("readAPNG", readAPNG);
	def("writeAPNG", writeAPNG);

	def("loadBSD500", loadBSD500);
	def("loadBSD300", loadBSD300);
	def("loadBSD50", loadBSD50);

	def("loadVOC2007", loadVOC<2007,false,false>);
	def("loadVOC2007_detect", loadVOC<2007,true,false>);
	def("loadVOC2007_detect_difficult", loadVOC<2007,true,true>);
	def("loadVOC2010", loadVOC<2010,false,false>);
	def("loadVOC2010_detect", loadVOC<2010,true,false>);
	def("loadVOC2010_detect_difficult", loadVOC<2010,true,true>);
	def("loadVOC2012", loadVOC<2012,false,false>);
	def("loadVOC2012_detect", loadVOC<2012,true,false>);
	def("loadVOC2012_detect_difficult", loadVOC<2012,true,true>);

//	def("loadNYU_nocrop", loadNYU_nocrop);
//	def("loadNYU04_nocrop", loadNYU04_nocrop);
//	def("loadNYU40_nocrop", loadNYU40_nocrop);
//	def("loadNYU", loadNYU);
//	def("loadNYU04", loadNYU04);
//	def("loadNYU40", loadNYU40);
//	def("labelsNYU", labelsNYU);
//	def("labelsNYU04", labelsNYU04);
//	def("labelsNYU40", labelsNYU40);
	def("loadCOCO2014", loadCOCO2014);
	def("cocoNFolds", cocoNFolds);
	def("overlapCOCO", overlapCOCO);
//	def("loadWeizmann", loadWeizmann, loadWeizmann_overload(args("train", "test", "n_train"), "Load the Weizmann horse dataset"));

	// Boundary detection evaluation
	def("evalBoundary", evalBoundary );
	def("evalBoundaryAll", evalBoundaryAll );
	def("evalSegmentBoundaryAll", evalSegmentBoundaryAll );

	// Proposal evaluation
	def("evaluateSegmentProposals", evaluateSegmentProposals1);
	def("evaluateSegmentProposals", evaluateSegmentProposals2);
	def("evaluateBoxProposals", evaluateBoxProposals1);
	def("evaluateBoxProposals", evaluateBoxProposals2);
	// Segment evaluation
//	def("proposeAndEvaluate",proposeAndEvaluate1<Proposal>);
//	def("proposeAndEvaluate",proposeAndEvaluate1<CRFProposals>);
//	def("proposeAndEvaluate",proposeAndEvaluate2<Proposal>);
//	def("proposeAndEvaluate",proposeAndEvaluate2<CRFProposals>);

	// Raw evaluation functions
//	def("evaluate",evaluate<list,list>);
//	def("evaluate",evaluate<RMatrixXs,RMatrixXb>);
//	def("evaluate",evaluate2<list,list>);
//	def("evaluate",evaluate2<RMatrixXs,RMatrixXb>);
//	def("evaluate",evaluate3);

	// Auxillary
//	def("regionsToMask",regionsToMask);
//	def("regionsToSeg",regionsToSeg);

//	def("showClosest",showClosest<RMatrixXs>);
//	def("showClosest",showClosest< std::vector<Polygons> >);

	class_<EmptyDirs>("dirs")
	.add_static_property("berkeley",make_getter(berkeley_dir),make_setter(berkeley_dir))
//	.add_static_property("nyu",make_getter(nyu_dir),make_setter(nyu_dir))
//	.add_static_property("weizmann",make_getter(weizmann_dir),make_setter(weizmann_dir))
//	.add_static_property("coco",make_getter(coco_dir),make_setter(coco_dir))
//	.add_static_property("voc",make_getter(voc_dir),make_setter(voc_dir));
	;
}
