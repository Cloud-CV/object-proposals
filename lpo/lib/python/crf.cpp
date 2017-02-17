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
#include "crf/crf.h"
#include "crf/crffeatures.h"
#include "crf/loss.h"
#include "segmentation/segmentation.h"
#include "util.h"
#include "lpo.h"
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>

void BinaryCRF_train1( BinaryCRF & that, const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & gt ) {
	that.train( f, gt );
}
void BinaryCRF_train2( BinaryCRF & that, const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & gt, const TrainingLoss & loss ) {
	that.train( f, gt, loss );
}
VectorXf BinaryCRF_map( BinaryCRF & that, const std::shared_ptr<BinaryCRFFeatures> & f ) {
	return that.map( f );
}
VectorXf BinaryCRF_inference( const VectorXf & u, const Edges & g, const VectorXf & w ) {
	return BinaryCRF::inference( u, g, w );
}

void defineCRF() {
	ADD_MODULE(crf);
	
	class_<BinaryCRFFeatures, std::shared_ptr<BinaryCRFFeatures>, boost::noncopyable>("BinaryCRFFeatures",no_init)
	.add_property("unary", make_function( &BinaryCRFFeatures::unary, return_value_policy<return_by_value>() ) )
	.add_property("pairwise", make_function( &BinaryCRFFeatures::pairwise, return_value_policy<return_by_value>() ) )
	.add_property("graph", make_function( &BinaryCRFFeatures::graph, return_value_policy<return_by_value>() ) );
	
	class_<StaticBinaryCRFFeatures, std::shared_ptr<StaticBinaryCRFFeatures>, bases<BinaryCRFFeatures> >("StaticBinaryCRFFeatures",init<ImageOverSegmentation>());
	implicitly_convertible< std::shared_ptr<StaticBinaryCRFFeatures>, std::shared_ptr<BinaryCRFFeatures> >();
	
	class_<BinaryCRF>( "BinaryCRF" )
	.def( "inference", &BinaryCRF_inference )
	.staticmethod( "inference" )
	.def( "energy", &BinaryCRF::energy )
	.staticmethod( "energy" )
	.def( "inferenceWithLoss", &BinaryCRF::inferenceWithLoss )
	.staticmethod( "inferenceWithLoss" )
	.def( "train", BinaryCRF_train1 )
	.def( "train", static_cast<void (BinaryCRF::*)( const std::shared_ptr<BinaryCRFFeatures>&, const VectorXs&)>( &BinaryCRF::train ) )
	.def( "train", BinaryCRF_train2 )
	.def( "train", static_cast<void (BinaryCRF::*)( const std::shared_ptr<BinaryCRFFeatures>&, const VectorXs&, const TrainingLoss &)>( &BinaryCRF::train ) )
	.def( "train1Slack", &BinaryCRF::train1Slack )
	.def( "trainNSlack", &BinaryCRF::trainNSlack )
	.def( "diverseMBest", &BinaryCRF::diverseMBest )
	.def( "map", &BinaryCRF_map )
	.def( "e", &BinaryCRF::e )
	.def_pickle(SaveLoad_pickle_suite<BinaryCRF>());
	
	class_<TrainingLoss,std::shared_ptr<TrainingLoss>,boost::noncopyable>( "TrainingLoss", no_init )
	.def("isLinear", &TrainingLoss::isLinear)
	.def("evaluate", static_cast<float (TrainingLoss::*)(float,float,float,float)const>(&TrainingLoss::evaluate) )
	.def("evaluate", static_cast<float (TrainingLoss::*)(const VectorXf&, const VectorXf&)const>(&TrainingLoss::evaluate) );
	
	class_<HammingLoss,std::shared_ptr<HammingLoss>, bases<TrainingLoss> >( "HammingLoss", init<float,float>() )
	.def(init<>());
	implicitly_convertible< std::shared_ptr<HammingLoss>, std::shared_ptr<TrainingLoss> >();
	
	class_<AverageHammingLoss,std::shared_ptr<AverageHammingLoss>, bases<TrainingLoss> >( "AverageHammingLoss", init<float>() )
	.def(init<>());
	implicitly_convertible< std::shared_ptr<AverageHammingLoss>, std::shared_ptr<TrainingLoss> >();
	
	class_<LinearJaccardLoss,std::shared_ptr<LinearJaccardLoss>, bases<TrainingLoss> >( "LinearJaccardLoss", init<float>() )
	.def(init<>());
	implicitly_convertible< std::shared_ptr<LinearJaccardLoss>, std::shared_ptr<TrainingLoss> >();
	
	class_<ApproximateJaccardLoss,std::shared_ptr<ApproximateJaccardLoss>, bases<TrainingLoss> >( "ApproximateJaccardLoss", init<float,float>() )
	.def(init<float>())
	.def(init<>());
	implicitly_convertible< std::shared_ptr<ApproximateJaccardLoss>, std::shared_ptr<TrainingLoss> >();
	
	class_<JaccardLoss,std::shared_ptr<JaccardLoss>, bases<TrainingLoss> >( "JaccardLoss", init<float>() )
	.def(init<>());
	implicitly_convertible< std::shared_ptr<JaccardLoss>, std::shared_ptr<TrainingLoss> >();
}
