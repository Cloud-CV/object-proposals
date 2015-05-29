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
#include "segmentation/gbs.h"
#include "segmentation/segmentation.h"
#include "segmentation/iouset.h"
#include "contour/structuredforest.h"
#include "contour/directedsobel.h"
#include "lpo.h"
#include "util.h"
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>

template<typename BDetector>
std::vector< std::shared_ptr<ImageOverSegmentation> > generateGeodesicKMeans1( const BDetector & det, const list & ims, int approx_N ) {
	const int N = len(ims);
	std::vector<Image8u*> img(N);
	for( int i=0; i<N; i++ )
		img[i] = extract<Image8u*>( ims[i] );
	std::vector< std::shared_ptr<ImageOverSegmentation> > ios( N );
#pragma omp parallel for
	for( int i=0; i<N; i++ )
		ios[i] = geodesicKMeans( *img[i], det, approx_N, 2 );
	return ios;
}
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS( ImageOverSegmentation_boundaryMap_overload, ImageOverSegmentation::boundaryMap, 0, 1 )
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS( ImageOverSegmentation_projectSegmentation_overload, ImageOverSegmentation::projectSegmentation, 1, 2 )
void defineSegmentation() {
	ADD_MODULE(segmentation);
	
	// Helpers
	class_<IOUSet>("IOUSet", init<ImageOverSegmentation>() )
	.def( "intersects", static_cast<bool (IOUSet::*)(const VectorXb &, float) const>(&IOUSet::intersects) )
	.def( "add", &IOUSet::add );
	
	/***** Over Segmentation *****/
	class_<OverSegmentation,std::shared_ptr<OverSegmentation> >( "OverSegmentation", init<const Edges &, const VectorXf &>() )
	.def(init<const Edges &>())
	.add_property("Ns",&OverSegmentation::Ns)
	.add_property("edges",make_function(&OverSegmentation::edges,return_value_policy<return_by_value>()))
	.add_property("edge_weights",make_function(&OverSegmentation::edgeWeights,return_value_policy<return_by_value>()),&OverSegmentation::setEdgeWeights)
	.def_pickle( SaveLoad_pickle_suite_shared_ptr<OverSegmentation>() );
	
	class_< ImageOverSegmentation,std::shared_ptr<ImageOverSegmentation>,bases<OverSegmentation> >( "ImageOverSegmentation", init<>() )
	.def("boundaryMap",&ImageOverSegmentation::boundaryMap, ImageOverSegmentation_boundaryMap_overload())
	.def("projectSegmentation",&ImageOverSegmentation::projectSegmentation, ImageOverSegmentation_projectSegmentation_overload())
	.def("project",static_cast<VectorXf (ImageOverSegmentation::*)(const RMatrixXf&,const std::string &)const>( &ImageOverSegmentation::project ))
	.def("project",static_cast<RMatrixXf (ImageOverSegmentation::*)(const Image&,const std::string &)const>( &ImageOverSegmentation::project ))
	.def("projectBoundary",static_cast<VectorXf (ImageOverSegmentation::*)(const RMatrixXf&,const std::string &)const>( &ImageOverSegmentation::projectBoundary ))
	.def("projectBoundary",static_cast<VectorXf (ImageOverSegmentation::*)(const RMatrixXf&,const RMatrixXf&,const std::string &)const>( &ImageOverSegmentation::projectBoundary ))
	.def("maskToBox",&ImageOverSegmentation::maskToBox)
	.add_property("s",make_function(&ImageOverSegmentation::s,return_value_policy<return_by_value>()))
	.add_property("image",make_function(&ImageOverSegmentation::image,return_value_policy<return_by_value>()))
	.def_pickle( SaveLoad_pickle_suite_shared_ptr<ImageOverSegmentation>() );
	implicitly_convertible< std::shared_ptr<ImageOverSegmentation>, std::shared_ptr<OverSegmentation> >();
	
	class_< std::vector< std::shared_ptr<ImageOverSegmentation> > >("VecImageOverSegmentation")
	.def( vector_indexing_suite< std::vector< std::shared_ptr<ImageOverSegmentation> >, true >() )
	.def_pickle( VectorSaveLoad_pickle_suite_shared_ptr<ImageOverSegmentation>() );
	
	def("geodesicKMeans",static_cast<std::shared_ptr<ImageOverSegmentation>(*)(const Image8u &, const BoundaryDetector &, int, int)>(geodesicKMeans));
	def("geodesicKMeans",static_cast<std::shared_ptr<ImageOverSegmentation>(*)(const Image8u &, const BoundaryDetector &, int)>(geodesicKMeans));
	def("geodesicKMeans",static_cast<std::shared_ptr<ImageOverSegmentation>(*)(const Image8u &, const StructuredForest &, int, int)>(geodesicKMeans));
	def("geodesicKMeans",static_cast<std::shared_ptr<ImageOverSegmentation>(*)(const Image8u &, const StructuredForest &, int)>(geodesicKMeans));
	def("geodesicKMeans",static_cast<std::shared_ptr<ImageOverSegmentation>(*)(const Image8u &, const DirectedSobel &, int, int)>(geodesicKMeans));
	def("geodesicKMeans",static_cast<std::shared_ptr<ImageOverSegmentation>(*)(const Image8u &, const DirectedSobel &, int)>(geodesicKMeans));
	
	def( "generateGeodesicKMeans", &generateGeodesicKMeans1<BoundaryDetector> );
	def( "generateGeodesicKMeans", &generateGeodesicKMeans1<StructuredForest> );
	def( "generateGeodesicKMeans", &generateGeodesicKMeans1<DirectedSobel> );
	
	def( "mergeOverSegmentations", &mergeOverSegmentations );
	
	def("gbs", gbs );
	
	class_<GBS>("GBS",init<Image>())
	.def("compute",&GBS::compute);
}
