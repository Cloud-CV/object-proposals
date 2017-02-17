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
#include "segmentation/segmentation.h"
#include "proposals/seed.h"
#include "proposals/proposal.h"
#include "crf/loss.h"
#include "proposals/lpo.h"
#include "lpo.h"
#include "util.h"
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>


void LPO_addGBS1( LPO & that, const std::string & color_space, const list & params, int max_size ) {
	that.addGBS( color_space, to_vector<float>(params), max_size );
}
void LPO_addGBS2( LPO & that, const std::string & color_space, const list & params ) {
	LPO_addGBS1( that, color_space, params, 1000 );
}
void LPO_train1( LPO & that, const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const list & gt, float f0 ) {
	if( len(gt) == 0 ) return;
	// Pascal segments
	if( extract<RMatrixXs>(gt[0]).check() )
		that.train( ios, to_vector< RMatrixXs >( gt ), f0 );
	// COCO segments
	else if( extract< std::vector<Polygons> >(gt[0]).check() )
		that.train( ios, to_vector< std::vector<Polygons> >( gt ), f0 );
	else
		printf("Unknown ground truth type, not training!\n");
}
std::vector< Proposals > makeProp( const Proposals & p ) {
	return std::vector<Proposals>( 1, p );
}
std::vector< Proposals > makeProp( const std::vector< Proposals > & p ) {
	return p;
}
template<typename T>
std::vector< std::vector< Proposals > > proposeMany1( const T & that, const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios ) {
	std::vector< std::vector< Proposals > > r( ios.size() );
	#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ )
		r[i] = makeProp( that.propose( *(ios[i]) ) );
	return r;
}
template<typename T>
std::vector< std::vector< Proposals > > proposeMany2( const T & that, const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, float min_iou ) {
	std::vector< std::vector< Proposals > > r( ios.size() );
	#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ )
		r[i] = makeProp( that.propose( *(ios[i]), min_iou ) );
	return r;
}
template<typename T>
std::vector< std::vector< Proposals > > proposeMany3( const T & that, const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, float min_iou, int model_id ) {
	std::vector< std::vector< Proposals > > r( ios.size() );
	#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ )
		r[i] = makeProp( that.propose( *(ios[i]), min_iou, model_id ) );
	return r;
}
template<typename T>
std::vector< std::vector< Proposals > > proposeMany4( const T & that, const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, float min_iou, bool box_nms ) {
	std::vector< std::vector< Proposals > > r( ios.size() );
	#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ )
		r[i] = makeProp( that.propose( *(ios[i]), min_iou, -1, box_nms ) );
	return r;
}

/*********************************/
/*********** LPO Model ***********/
/*********************************/
class PythonModel: public ExhaustiveLPOModel {
protected:
	std::vector<VectorXf> params_;
	std::string module_name_, class_name_;
	object getClass() const {
		object module = import(module_name_.c_str());
		return module.attr(class_name_.c_str());
	}
public:
	PythonModel( const std::string & module_name = "", const std::string & class_name = "" ): module_name_(module_name), class_name_(class_name) {
	}
	virtual std::vector<VectorXf> allParameters() const {
		list all_params = extract<list>(getClass().attr("all_parameters")());
		std::vector<VectorXf> r;
		for( int i=0; i<len(all_params); i++ )
			r.push_back( extract<VectorXf>(all_params[i]) );
		return r;
	}
	virtual void load( std::istream & is ) {
		module_name_ = loadString( is );
		class_name_ = loadString( is );
		loadVector<VectorXf>( is );
	}
	virtual void save( std::ostream & os ) const {
		saveString( os, module_name_ );
		saveString( os, class_name_ );
		saveVector( os, params_ );
	}
	virtual std::vector<Proposals> generateProposals( const ImageOverSegmentation & ios, const std::vector<VectorXf> & params ) const {
		list props = extract<list>( getClass().attr("generateProposals")(ios,params) );
		return to_vector<Proposals>(props);
	}
};
DEFINE_MODEL(PythonModel);

BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS( LearnedSeed_train, LearnedSeed::train, 3, 4 )
void defineProposals() {
	ADD_MODULE(proposals);

	class_<Proposals>( "Proposals" )
	.def( init<RMatrixXs, RMatrixXb>() )
	.def( "toBoxes", &Proposals::toBoxes )
	.add_property("s", make_getter(&Proposals::s, return_value_policy<return_by_value>()) )
	.add_property("p", make_getter(&Proposals::p, return_value_policy<return_by_value>()) )
	.def_pickle( SaveLoad_pickle_suite<Proposals>() );

	class_< std::vector<Proposals> >( "VecProposals" )
	.def( vector_indexing_suite< std::vector<Proposals>, true >() );

	class_< std::vector< std::vector<Proposals> > >( "VecVecProposals" )
	.def( vector_indexing_suite< std::vector< std::vector<Proposals> >, true >() );

	//***** Seeds *****//
	class_< SeedFunction, std::shared_ptr<SeedFunction>, boost::noncopyable >( "SeedFunction", no_init )
	.def("compute", &SeedFunction::compute);
	class_< ImageSeedFunction, std::shared_ptr<ImageSeedFunction>, bases<SeedFunction>, boost::noncopyable >( "ImageSeedFunction", no_init );

	class_< RegularSeed, std::shared_ptr<RegularSeed>, bases<ImageSeedFunction> >( "RegularSeed" );
	implicitly_convertible< std::shared_ptr<RegularSeed>, std::shared_ptr<SeedFunction> >();

	class_< GeodesicSeed, std::shared_ptr<GeodesicSeed>, bases<SeedFunction> >( "GeodesicSeed" )
	.def(init<float>())
	.def(init<float,float>())
	.def(init<float,float,float>())
	.def_pickle(SaveLoad_pickle_suite<GeodesicSeed>());
	implicitly_convertible< std::shared_ptr<GeodesicSeed>, std::shared_ptr<SeedFunction> >();

	class_< RandomSeed, std::shared_ptr<RandomSeed>, bases<SeedFunction> >( "RandomSeed" )
	.def_pickle(SaveLoad_pickle_suite<RandomSeed>());
	implicitly_convertible< std::shared_ptr<RandomSeed>, std::shared_ptr<SeedFunction> >();

	class_< LearnedSeed, std::shared_ptr<LearnedSeed>, bases<SeedFunction> >("LearnedSeed")
	.def( init<std::string>() )
	.def( "train", &LearnedSeed::train, LearnedSeed_train() )
	.def( "load", static_cast<void(LearnedSeed::*)(const std::string &)>(&LearnedSeed::load) )
	.def( "save", static_cast<void(LearnedSeed::*)(const std::string &)const>(&LearnedSeed::save) )
	.def_pickle(SaveLoad_pickle_suite<LearnedSeed>());
	implicitly_convertible< std::shared_ptr<LearnedSeed>, std::shared_ptr<SeedFunction> >();

	//***** LPO *****//
	class_<LPO>("LPO",init<>())
	.def("train",LPO_train1)
	.def("addGlobal",&LPO::addGlobal)
	.def("addSeed",&LPO::addSeed)
	.def("addGBS",&LPO_addGBS1)
	.def("addGBS",&LPO_addGBS2)
	.def("propose",&LPO::propose)
	.def("propose",&proposeMany1<LPO>)
	.def("propose",&proposeMany2<LPO>)
	.def("propose",&proposeMany3<LPO>)
	.def("propose",&proposeMany4<LPO>)
	.def("load",static_cast<void (LPO::*)(const std::string &)>(&LPO::load))
	.def("save",static_cast<void (LPO::*)(const std::string &) const>(&LPO::save))
	.add_property("nModels",&LPO::nModels)
	.add_property("modelTypes",&LPO::modelTypes)
	.def_pickle(SaveLoad_pickle_suite_shared_ptr<LPO>());
}
