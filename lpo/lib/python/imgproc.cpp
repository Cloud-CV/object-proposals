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
#include "imgproc/color.h"
#include "imgproc/filter.h"
#include "imgproc/gradient.h"
#include "imgproc/morph.h"
#include "imgproc/nms.h"
#include "imgproc/resample.h"
#include "util/util.h"
#include "imgproc.h"
#include "lpo.h"
#include "util.h"
#include <boost/python/def_visitor.hpp>


/****************  color.cpp  ****************/
typedef void (*ConvFunction)(Image &, const Image &);
static ConvFunction cfun[] = {rgb2luv,srgb2luv,rgb2lab,srgb2lab,rgb2hsv};
template<int T>
static Image convert( const Image & image ) {
	if( image.C() != 3 )
		throw std::invalid_argument( "3-channel image required" );
	Image r( image.W(), image.H(), 3 );
	cfun[T]( r, image );
	return r;
}

/****************  filter.cpp  ****************/
static RMatrixXf percentileFilter_m( const RMatrixXf & image, int rad, float p ) {
	RMatrixXf r( image.rows(), image.cols() );
	percentileFilter( r.data(), image.data(), image.cols(), image.rows(), 1, rad, p );
	return r;
}
#define defFilter( name )\
static RMatrixXf name##_m( const RMatrixXf & image, int rad ) {\
	RMatrixXf r( image.rows(), image.cols() );\
	name( r.data(), image.data(), image.cols(), image.rows(), 1, rad );\
	return r;\
}\
static Image name##_im( const Image & image, int rad ) {\
	Image r( image.W(), image.H(), image.C() );\
	name( r.data(), image.data(), image.W(), image.H(), image.C(), rad );\
	return r;\
}
defFilter( boxFilter )
defFilter( tentFilter )
defFilter( gaussianFilter )
static RMatrixXf exactGaussianFilter_m( const RMatrixXf & image, int rad, int R ) {
	RMatrixXf r( image.rows(), image.cols() );
	exactGaussianFilter( r.data(), image.data(), image.cols(), image.rows(), 1, rad, R );
	return r;
}

/****************  gradient.cpp  ****************/
static tuple gradientMagAndOri2( const Image & image, int norm_rad, float norm_const ) {
	RMatrixXf gm, go;
	gradientMagAndOri( gm, go, image, norm_rad, norm_const );
	return make_tuple(gm, go);
}
static Image gradientHist2( const RMatrixXf & gm, const RMatrixXf & go, int nori, int nbins=1) {
	Image r;
	gradientHist( r, gm, go, nori, nbins );
	return r;
}

/****************  morph.cpp  ****************/
static RMatrixXb thin( const RMatrixXb & image ) {
	RMatrixXb r = image;
	thinningGuoHall( r );
	return r;
}

/****************  nms.cpp  ****************/
static RMatrixXf suppressBnd2( const RMatrixXf &im, int b ) {
	RMatrixXf r = im;
	suppressBnd( r, b );
	return r;
}
/****************  image.cpp  ****************/
template<typename T> struct ImageTypeStr {
	static const std::string s;
};
template<> const std::string ImageTypeStr<uint8_t>::s = "u1";
template<> const std::string ImageTypeStr<float>::s = "f4";

template<typename IM>
struct Image_indexing_suite: def_visitor<Image_indexing_suite<IM> > {
	typedef typename IM::value_type value_type;

	struct Image_pickle_suite : pickle_suite {
		static tuple getinitargs(const IM& im) {
			return make_tuple( im.W(), im.H(), im.C() );
		}

		static object getstate(const IM& im) {
			const int N = im.W()*im.H()*im.C()*sizeof(value_type);
			return object( handle<>( PyBytes_FromStringAndSize( (const char*)im.data(), N ) ) );
		}

		static void setstate(IM& im, const object & state) {
			if(!PyBytes_Check(state.ptr()))
				throw std::invalid_argument("Failed to unpickle, unexpected type!");
			const int N = im.W()*im.H()*im.C()*sizeof(value_type);
			if( PyBytes_Size(state.ptr()) != N )
				throw std::invalid_argument("Failed to unpickle, unexpected size!");
			memcpy( im.data(), PyBytes_AS_STRING(state.ptr()), N );
		}
	};

	template <class classT>	void visit(classT& c) const {
		c
		.def("__init__",make_constructor(&Image_indexing_suite::init1))
		.def("__init__",make_constructor(&Image_indexing_suite::init2))
		// TODO:
//		.def("__init__",make_constructor(&Image_indexing_suite::init3))
		.add_property("W",&IM::W)
		.add_property("H",&IM::H)
		.add_property("C",&IM::C)
		.def("tileC",&IM::tileC)
		.def_pickle(Image_pickle_suite())
		.add_property("__array_interface__", &Image_indexing_suite::array_interface);
	}
	static IM * init1() {
		return new IM();
	}
	static IM * init2( int W, int H, int C ) {
		return new IM( W, H, C );
	}
	// TODO: Implement properly
//	static IM * init3( const np::ndarray & d ) {
//		checkArray( d, value_type, 2, 3, true );
//
//		IM* r = new IM(d.shape(1),d.shape(0),d.get_nd()>2?d.shape(2):1);
//		memcpy( r->data(), d.get_data(), r->W()*r->H()*r->C()*sizeof(value_type) );
//		return r;
//	}
	static dict array_interface( IM & im ) {
		dict r;
		r["shape"] = make_tuple( im.H(), im.W(), im.C() );
		r["typestr"] = ImageTypeStr<value_type>::s;
		r["data"] = make_tuple((size_t)im.data(),1);
		r["version"] = 3;
		return r;
	}
};
template<typename I1, typename I2>
I1 convertImage( const I2 & im ) {
	return im;
}
void defineImgProc() {
	ADD_MODULE(imgproc);
	// Color
	def("rgb2luv",convert<0>);
	def("srgb2luv",convert<1>);
	def("rgb2lab",convert<2>);
	def("srgb2lab",convert<3>);
	def("rgb2hsv",convert<4>);
	// Filters
	def("boxFilter",boxFilter_m);
	def("boxFilter",boxFilter_im);
	def("tentFilter",tentFilter_m);
	def("tentFilter",tentFilter_im);
	def("gaussianFilter",gaussianFilter_m);
	def("gaussianFilter",gaussianFilter_im);
	def("exactGaussianFilter",exactGaussianFilter_m);
	def("percentileFilter",percentileFilter_m);
	// Gradient
	def("gradientMag",gradientMag);
	def("gradientMagAndOri",gradientMagAndOri2);
	def("gradientHist",gradientHist2);
	// Morphology
	def("thin",thin);
	// NMS
	def("nms",nms);
	def("suppressBnd",suppressBnd2);
	// Downsampling
	def("downsample", (RMatrixXf(*)( const RMatrixXf &, int, int ))downsample);
	def("downsample", (Image(*)( const Image &, int, int ))downsample);
	def("padIm",(Image(*)(const Image &, int))padIm);

	// Patch extraction
	def("extractPatches",static_cast<std::vector<RMatrixXb>(*)(const RMatrixXb&,const RMatrixXi&,int,int)>(&extractPatches));
	def("extractPatches",static_cast<std::vector<RMatrixXs>(*)(const RMatrixXs&,const RMatrixXi&,int,int)>(&extractPatches));
	def("extractPatches",static_cast<std::vector<RMatrixXb>(*)(const std::vector<RMatrixXb>&,const RMatrixXi&,int,int)>(&extractPatches));
	def("extractPatches",static_cast<std::vector<RMatrixXs>(*)(const std::vector<RMatrixXs>&,const RMatrixXi&,int,int)>(&extractPatches));

	// Image and Image8u
	def("imread",imread);
	def("imwrite",imwrite);

	class_<Image,std::shared_ptr<Image> >("Image")
	.def(Image_indexing_suite<Image>())
	.def("toImage8u",convertImage<Image,Image8u>);
	class_<Image8u,std::shared_ptr<Image8u> >("Image8u")
	.def(Image_indexing_suite<Image8u>())
	.def("toImage",convertImage<Image,Image8u>);
}
