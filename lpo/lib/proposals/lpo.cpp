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
#include "lpo.h"
#include "lpo/crfmodel.h"
#include "lpo/oversegmentationmodel.h"
#include "segmentation/segmentation.h"
#include "segmentation/iouset.h"
#include "util/floc.h"
#include "util/algorithm.h"
#include <iostream>
#include <fstream>

static const bool VERBOSE = true;

void LPO::addGlobal() {
	models_.push_back( std::make_shared<GlobalCRFModel>() );
}
void LPO::addSeed( std::shared_ptr<SeedFunction> seed, int max_seed ) {
	models_.push_back( std::make_shared<SeedCRFModel>( seed, max_seed ) );
}
void LPO::addGBS(const std::string& color_space, const std::vector< float >& params, int max_size) {
	models_.push_back( std::make_shared<GBSModel>( color_space, params, max_size ) );
}
static const int PROP_MAGIC = 0x960902;
void LPO::save( std::ostream & os ) const {
	os.write( (const char*)&PROP_MAGIC, sizeof(PROP_MAGIC) );
	int n = models_.size();
	os.write( (const char*)&n, sizeof(n) );
	for( int i=0; i<n; i++ )
		saveLPOModel( os, models_[i] );
}
void LPO::load( std::istream & is ) {
	int n = 0;
	is.read( (char*)&n, sizeof(n) );
	eassert( n == PROP_MAGIC );
	n=0;
	is.read( (char*)&n, sizeof(n) );
	models_.clear();
	for( int i=0; i<n; i++ ) 
		models_.push_back( loadLPOModel(is) );
}
void LPO::save( const std::string & fn ) const {
	std::ofstream os( fn.c_str(), std::ios::binary | std::ios::out );
	save( os );
}
void LPO::load( const std::string & fn ) {
	std::ifstream is( fn.c_str(), std::ios::binary | std::ios::in );
	load( is );
}
std::vector< Proposals > LPO::propose(const ImageOverSegmentation& ios, float max_iou, int model_id, bool box_nms) const {
	std::vector< Proposals > all_prop;
	// Generate all proposals
	for( int i=0; i<models_.size(); i++ ) 
		if( i==model_id || model_id==-1 ){
			const std::vector<Proposals> & props = models_[i]->propose( ios );
			for( const Proposals & p: props ) {
				// Can we merge some proposal maps?
				bool merge = false;
				for( Proposals & pp: all_prop ) {
					if( pp.s == p.s ) {
						eassert( pp.p.cols() == p.p.cols() );
						
						// Merge the proposal maps
						merge = true;
						RMatrixXb new_p( pp.p.rows()+p.p.rows(), p.p.cols() );
						new_p.topRows  ( pp.p.rows() ) = pp.p;
						new_p.bottomRows( p.p.rows() ) = p.p;
						pp.p = new_p;
						break;
					}
				}
				if( !merge )
					all_prop.push_back( p );
			}
		}
	if( box_nms )
		return boxNms( all_prop, max_iou );
	// Remove empty proposals and (near) duplicates
	// Only doing it on CRF proposals is much faster and doesn't generate
	// too many more proposals (~100 more)
	all_prop[0] = nms( all_prop[0], max_iou );
	return all_prop;
// 	return nms( all_prop, max_iou );
}
static VectorXi find( const VectorXb & mask ) {
	VectorXi r( mask.cast<int>().sum() );
	for( int i=0, k=0; i<mask.size(); i++ )
		if( mask[i] )
			r[k++] = i;
	return r;
}
static int nSamples( const std::vector< RMatrixXs >& gt ) {
	int r = 0;
	for( const auto & g: gt )
		r += g.maxCoeff()+1;
	return r;
}
static int nSamples( const std::vector< RMatrixXi >& boxes ) {
	int r = 0;
	for( const auto & g: boxes )
		r += g.rows();
	return r;
}
static int nSamples( const std::vector< std::vector< Polygons > >& gt ) {
	int r = 0;
	for( const auto & g: gt )
		r += g.size();
	return r;
}
void LPO::train(const std::vector< std::shared_ptr< ImageOverSegmentation > >& ios, const std::vector< RMatrixXs >& gt, const float f0) {
	std::vector< std::shared_ptr<LPOModelTrainer> > trainers;
	for( int i=0; i<models_.size(); i++ )
		trainers.push_back( models_[i]->makeTrainer( ios, gt ) );
	train( trainers, nSamples( gt ), f0 );
}
void LPO::train(const std::vector< std::shared_ptr< ImageOverSegmentation > >& ios, const std::vector< std::vector< Polygons > >& gt, const float f0) {
	std::vector< std::shared_ptr<LPOModelTrainer> > trainers;
	for( int i=0; i<models_.size(); i++ )
		trainers.push_back( models_[i]->makeTrainer( ios, gt ) );
	train( trainers, nSamples( gt ), f0 );
}
template<typename T>
std::vector<T> filter( const std::vector<T> & v, const VectorXb & x ) {
	std::vector<T> r( x.cast<int>().array().sum() );
	for( int i=0, j=0; i<x.size(); i++ )
		if( x[i] )
			r[j++] = v[i];
	return r;
}
struct TrainingParameters {
	int trainer_id;
	std::shared_ptr< LPOModelTrainer > trainer;
	VectorXf parameters, accuracy;
	std::vector<VectorXf> latent_variables;
	bool fit( int sample ) {
		parameters = trainer->fit( sample );
		return parameters.size();
	}
	bool refit( const VectorXb & samples ) {
		VectorXf old_parameters = parameters;
		parameters = trainer->refit( find(samples), filter(latent_variables,samples), parameters );
		return parameters.size() != old_parameters.size() || !old_parameters.isApprox( parameters );
	}
	void evaluate() {
		accuracy = trainer->proposeAndEvaluate( parameters, latent_variables );
		if( latent_variables.size() != accuracy.size() )
			latent_variables.resize( accuracy.size() );
	}
	float nProposals() const {
		return trainer->averageProposalsPerParameter( parameters );
	}
};
RMatrixXf scoreMatrix( const std::vector<TrainingParameters> & params ) {
	eassert( params.size()>0 );
	int D = params.front().accuracy.size();
	RMatrixXf score( params.size(), D );
	for( int i=0; i<params.size(); i++ )
		score.row( i ) = params[i].accuracy.transpose();
	return score;
}
std::vector<TrainingParameters> filterParameters( const std::vector<TrainingParameters> & params, float f0 ) {
	eassert( params.size()>0 );
	// Compute the transportation cost
	RMatrixXf score = 1.f-scoreMatrix( params ).array();
	
	// Compute the facility cost
	VectorXf f = VectorXf::Constant(params.size(),f0);
	for( int i=0; i<params.size(); i++ )
		f[i] = params[i].nProposals()*f0;
	
	VectorXb r;
	{
		VectorXb x[1];
		float s[10] = {0.f};
		int N = sizeof(x) / sizeof(x[0]);
		x[0] = Floc::greedy( f, score );
		if( N > 1 )
			x[1] = Floc::jms( f, score );
		if( N > 2 )
			x[2] = Floc::myz( f, score );
		
		for( int i=0; i<N; i++ )
			s[i] = Floc::energy( f, score, x[i] );
			
// 		printf("Filter greedy = %f   jms = %f   myz = %f\n", s[0], s[1], s[2] );
		r = x[0];
		float rs = s[0];
		for( int i=1; i<N; i++ )
			if( s[i] < rs ) {
				rs = s[i];
				r = x[i];
			}
	}
	return filter( params, r );
}
void LPO::train(const std::vector< std::shared_ptr< LPOModelTrainer > >& trainers, int n_samples, const float f0) {
	static std::mt19937 rand;
	const int N_RANDOM = 100, NIT=10;
	
	printf("%d training segments\n", n_samples );
	
	// Train the ensemble of models
	VectorXf current_best_accuracy = VectorXf::Zero( n_samples );
	
	std::vector<TrainingParameters> parameters;
	
	std::vector< int > exhaustive_id, sampled_id;
	for( int i=0; i<trainers.size(); i++ )
		if(!!std::dynamic_pointer_cast<ExhaustiveLPOModelTrainer>(trainers[i]))
			exhaustive_id.push_back( i );
		else
			sampled_id.push_back( i );
	
	Timer timer;
	for( int it=0; it<NIT; it++ ) {
		timer.tic();
		
		// Genrate new training parameters
		std::vector<TrainingParameters> new_parameters;
		
		// Add exhaustive params
		for( int i: exhaustive_id ) {
			std::vector<VectorXf> all_params = std::dynamic_pointer_cast<ExhaustiveLPOModelTrainer>(trainers[i])->allParameters();
			for( int j=0; j<all_params.size(); j++ ) {
				TrainingParameters np;
				np.trainer_id = i;
				np.trainer = trainers[i];
				np.parameters = all_params[j];
				new_parameters.push_back( np );
			}
		}
		
		// Add sampled trainers
// 		VectorXi smpl = randomChoose( 1-current_best_accuracy.array(), N_RANDOM );
		VectorXi smpl = randomChoose( n_samples, N_RANDOM );
		if( sampled_id.size() ) {
#pragma omp parallel for schedule(dynamic)
			for( int i=0; i<smpl.size(); i++ )
				for( int n_rand=0; n_rand < 5; n_rand++ ) {
					TrainingParameters np;
					np.trainer_id = sampled_id[ rand()%sampled_id.size() ];
					np.trainer = trainers[ np.trainer_id ];
					if ( np.fit( smpl[i] ) ) {
#pragma omp critical
						new_parameters.push_back( np );
						break;
					}
				}
		}
		timer.toc("generate");
		
		for( TrainingParameters & p: new_parameters )
			p.evaluate();
		timer.toc("evaluate");
		
		// FLOC
		parameters.insert( parameters.end(), new_parameters.begin(), new_parameters.end() );
		parameters = filterParameters( parameters, f0 );
		new_parameters.clear();
		timer.toc("floc");
		
		current_best_accuracy = scoreMatrix( parameters ).colwise().maxCoeff();
		
		// Print some statistics
		if( VERBOSE ) {
			int n_prop = 0;
			std::unordered_map<std::string,int> cnt, cnt_prop;
			for( auto p: parameters ) {
				cnt[ p.trainer->name() ] += 1;
				cnt_prop[ p.trainer->name() ] += p.nProposals();
				n_prop += p.nProposals();
			}
			std::string info_s;
			for( auto c: cnt )
				info_s += " "+c.first+" = "+std::to_string( cnt_prop[c.first] )+" ("+std::to_string( c.second )+")";
			
			printf("  =%d [%s  total = %d] \t %f   %f\n", it, info_s.c_str(), n_prop, current_best_accuracy.array().mean(), n_prop*f0/n_samples );
		}
		
		// Refit
		for( TrainingParameters p: parameters )
			if( p.refit( p.accuracy.array()>=current_best_accuracy.array() ) ) {
				p.evaluate();
				new_parameters.push_back( p );
			}
		timer.toc("refit & evaluate");
		
		// FLOC
		parameters.insert( parameters.end(), new_parameters.begin(), new_parameters.end() );
		parameters = filterParameters( parameters, f0 );
		timer.toc("floc");
		
		current_best_accuracy = scoreMatrix( parameters ).colwise().maxCoeff();
		
		// Print some statistics
		if( VERBOSE ) {
			int n_prop = 0;
			std::unordered_map<std::string,int> cnt, cnt_prop;
			for( auto p: parameters ) {
				cnt[ p.trainer->name() ] += 1;
				cnt_prop[ p.trainer->name() ] += p.nProposals();
				n_prop += p.nProposals();
			}
			std::string info_s;
			for( auto c: cnt )
				info_s += " "+c.first+" = "+std::to_string( cnt_prop[c.first] )+" ("+std::to_string( c.second )+")";
			
			printf("IT=%d [%s  total = %d] \t %f   %f\n", it, info_s.c_str(), n_prop, current_best_accuracy.array().mean(), n_prop*f0/n_samples );
		}
	}
	// Gather and set parameters
	std::vector< std::vector< VectorXf > > params( trainers.size() );
	for( auto p: parameters )
		params[p.trainer_id].push_back( p.parameters );
	for( int i=0; i<trainers.size(); i++ )
		models_[i]->setParameters( params[i] );
}
int LPO::nModels() const{
	return models_.size();
}
std::vector< std::string > LPO::modelTypes() const{
	std::vector< std::string > r;
	for( auto m: models_ )
		r.push_back( modelName(m) );
	return r;
}
