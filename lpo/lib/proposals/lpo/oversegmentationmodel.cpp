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
#include "oversegmentationmodel.h"
#include "segmentation/segmentation.h"
#include "segmentation/gbs.h"
#include "imgproc/color.h"
#include "imgproc/filter.h"
#include "util/algorithm.h"
#include "util/util.h"

/* OverSegmentation based models */
OverSegmentationModel::OverSegmentationModel(const std::string & color_space, const std::vector<VectorXf> & all_params, int max_size):ExhaustiveLPOModel(all_params),color_space_(color_space), max_size_(max_size) {
}
Image OverSegmentationModel::convertColorSpace( const Image & im ) const {
	eassert( im.C() == 3 );
	Image r;
	if( color_space_ == "rgb" )
		r = im;
	else if( color_space_ == "hsv" )
		rgb2hsv( r, im );
	else if( color_space_ == "lab" ) {
		rgb2lab( r, im );
		// Undo Piotrs weird scaling (used in StructredForests)
		r.scale( 270. / 170. );
	}
	else if( color_space_ == "luv" ) {
		rgb2luv( r, im );
		// Undo Piotrs weird scaling (used in StructredForests)
		r.scale( 270. / 170. );
	}
	else if (color_space_ == "normrgb")
		rgb2normrgb( r, im );
	else
		throw std::invalid_argument( "Invalid color space!" );
	Image br( r.W(), r.H(), r.C() );
	gaussianFilter( br.data(), r.data(), r.W(), r.H(), r.C(), 1.0 );
	return br;
}
void OverSegmentationModel::load(std::istream& is){
	is.read( (char*)&max_size_, sizeof(max_size_) );
	color_space_ = loadString( is );
	ExhaustiveLPOModel::load(is);
}
void OverSegmentationModel::save(std::ostream& os) const{
	os.write( (const char*)&max_size_, sizeof(max_size_) );
	saveString( os, color_space_ );
	ExhaustiveLPOModel::save(os);
}
std::vector<Proposals> GBSModel::generateProposals( const ImageOverSegmentation & ios, const std::vector<VectorXf> & params ) const {
	GBS gbs( convertColorSpace(ios.image()) );
	std::vector<Proposals> r( params.size() );
	for( int i=0; i<params.size(); i++ ) {
		// Create the over-segmentation
		RMatrixXs s = gbs.compute( params[i][0]/255., params[i][0] );
		
		// Find all valid segments
		const int Ns = s.maxCoeff()+1;
		VectorXi cnt = bincount( s );
		VectorXb valid = (cnt.array()>0 && cnt.array() < max_size_);
		
		// Create the proposal mask
		RMatrixXb p = RMatrixXb::Zero(valid.cast<int>().sum(),Ns);
		for( int k=0,kk=0; k<cnt.size(); k++ )
			if( valid[k] )
				p( kk++, k ) = 1;
		
		r[i].s = s;
		r[i].p = p;
	}
	return r;
}
static std::vector<VectorXf> cvtParam( const std::vector<float> & v ) {
	std::vector<VectorXf> r( v.size() );
	for( int i=0; i<r.size(); i++ )
		r[i] = VectorXf::Ones( 1 )*v[i];
	return r;
}
GBSModel::GBSModel( const std::string & color_space, const std::vector<float> & all_parameters, int max_size ):OverSegmentationModel( color_space, cvtParam( all_parameters ), max_size ) {
}
DEFINE_MODEL(GBSModel);

