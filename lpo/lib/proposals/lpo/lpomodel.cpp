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
#include "lpomodel.h"
#include "crfmodel.h"
#include "oversegmentationmodel.h"
#include "segmentation/segmentation.h"
#include "util/util.h"
#include <random>

LPOModel::~LPOModel() {
}
LPOModelTrainer::~LPOModelTrainer() {
}

// Loading and saving functions
enum ModelID {
    GLOBAL_CRF_MODEL=0,
    SEED_CRF_MODEL=1,
    GBS_MODEL=2,
};

std::vector< std::shared_ptr<ModelRegister> > & getModelRegistry() {
	static std::vector< std::shared_ptr<ModelRegister> > model_registry;
	return model_registry;
}

void registerModel( const std::shared_ptr<ModelRegister> & r ) {
	getModelRegistry().push_back( r );
}
std::string modelName( const std::shared_ptr<LPOModel> & p ) {
	for( auto m: getModelRegistry() )
		if( m->istype( p ) )
			return m->name();
	return "";
}

void saveLPOModel( std::ostream & os, const std::shared_ptr<LPOModel> & p ) {
	std::string name = modelName( p );
	if(!name.size())
		throw std::invalid_argument("Failed to save LPOModel!");
	saveString( os, name );
	p->save( os );
}
std::shared_ptr<LPOModel> loadLPOModel( std::istream & is ) {
	std::shared_ptr<LPOModel> r;
	std::string name = loadString( is );
	for( auto m: getModelRegistry() )
		if( m->name() == name ) {
			r = m->make();
			break;
		}
	if(!r)
		throw std::invalid_argument("Unknown model type '"+name+"'!");
	r->load( is );
	return r;
}



/*** Exhaustive LPO Models ***/

class ExhaustiveLPOModelTrainerImplementation: public ExhaustiveLPOModelTrainer {
protected:
	std::string name_;
	std::vector<VectorXf> all_params_;
	std::vector< std::vector<float> > iou_;
	std::vector<float> prop_per_param_;
	int getParamId( const VectorXf & p ) const {
		int pid = 0;
		float b = (p - all_params_[pid]).array().abs().sum();
		for( int i=1; i<all_params_.size(); i++ )
			if( (p - all_params_[i]).array().abs().sum() < b ) {
				b = (p - all_params_[i]).array().abs().sum();
				pid = i;
			}
		return pid;
	}
public:
	ExhaustiveLPOModelTrainerImplementation( const std::string & name, const std::vector<VectorXf> & all_params, const std::vector< std::vector<float> > & iou, const std::vector<float> & prop_per_param ):name_(name), all_params_(all_params), iou_(iou), prop_per_param_(prop_per_param) {
	}
	// Fit a model to a specific sample
	virtual VectorXf fit( int sample ) const {
		VectorXf best_param = all_params_[0];
		float best_iou = 0;
		for( int k=0; k<all_params_.size(); k++ ) {
			if( iou_[k][sample] > best_iou ) {
				best_iou = iou_[k][sample];
				best_param = all_params_[k];
			}
		}
		return best_param;
	}
	// Refit the model to a bunch of samples (pass in any latent varaibles that we might have, plus the previous parameters)
	virtual VectorXf refit( const VectorXi & samples, const std::vector<VectorXf> & latent_variables, const VectorXf & previous_parameter ) const {
		return previous_parameter;
	}
	// Generate proposals using 'parameter's on image im_id. The function returns a set of latent_variables and proposals
	virtual VectorXf proposeAndEvaluate( const VectorXf & parameter, std::vector<VectorXf> & latent_variables ) const {
		int pid = getParamId( parameter );
		const int N = iou_[pid].size();
		VectorXf r( N );
		for( int i=0; i<N; i++ )
			r[i] = iou_[pid][i];
		return r;
	}
	// Average number of proposals per parameter
	virtual float averageProposalsPerParameter( const VectorXf & parameter ) const {
		return prop_per_param_[ getParamId( parameter ) ];
	}
	// List all possible parameters (instead of fitting)
	virtual std::vector<VectorXf> allParameters() const {
		return all_params_;
	}
	virtual std::string name() const {
		return name_;
	}
};
static int no( const RMatrixXs & gt ) {
	return gt.maxCoeff()+1;
}
static int no( const RMatrixXi & gt ) {
	return gt.rows();
}
static int no( const std::vector< Polygons > & gt ) {
	return gt.size();
}
#ifdef __GNUG__
#include <cxxabi.h>
#endif
template<typename T> std::string typeStr( const T & s ) {
#ifdef __GNUG__
	int status = -1;
	std::unique_ptr<char, void(*)(void*)> res {
		abi::__cxa_demangle(typeid(s).name(), NULL, NULL, &status),
		std::free
	};
	if( status == 0 )
		return res.get();
#endif
	return typeid(s).name();
}
template<typename T>
std::shared_ptr< ExhaustiveLPOModelTrainer > makeExhaustiveTrainer( const ExhaustiveLPOModel & that, const std::vector< std::shared_ptr< ImageOverSegmentation > >& ios, const std::vector< T >& gt ) {
	std::string name = typeStr(that);

	std::vector< VectorXf > params = that.all_params_;
	const int N = ios.size(), M = params.size();
	std::vector<int> oid( gt.size()+1 );
	std::transform( gt.begin(), gt.end(), oid.data()+1, static_cast<int(*)(const T&)>(&no) );
	std::partial_sum( oid.begin(), oid.end(), oid.begin() );

	std::vector< float > avg_prop( params.size(), 0. );
	std::vector< std::vector< float > > iou( params.size(), std::vector< float >(oid.back(),0.f) );
	#pragma omp parallel for
	for( int i=0; i<N; i++ ) {
		std::vector<Proposals> s = that.generateProposals( *ios[i], params );
		for( int j=0; j<M; j++ ) {
			Proposals p = s[j];

			SegmentationOverlap o(p.s, gt[i]);
			const int no = o.nObjects();
			eassert( oid[i]+no == oid[i+1] );

			auto best_iou = VectorXf::Map(iou[j].data()+oid[i],no);
			int n = p.p.rows();
			for( int k=0; k<n; k++ )
				best_iou = best_iou.array().max( o.iou( p.p.row(k) ).array() );

			#pragma omp atomic
			avg_prop[j] += 1.0 * n / N;
		}
	}
	return std::make_shared<ExhaustiveLPOModelTrainerImplementation>( name, params, iou, avg_prop );
}
ExhaustiveLPOModel::ExhaustiveLPOModel(const std::vector< VectorXf >& all_params):all_params_(all_params) {
}
void ExhaustiveLPOModel::load(std::istream& is) {
	params_ = loadVector<VectorXf>( is );
	all_params_ = loadVector<VectorXf>( is );
}
void ExhaustiveLPOModel::save(std::ostream& os) const {
	saveVector<VectorXf>( os, params_ );
	saveVector<VectorXf>( os, all_params_ );
}
std::vector< Proposals > ExhaustiveLPOModel::propose(const ImageOverSegmentation& ios) const {
	return generateProposals(ios,params_);
}
void ExhaustiveLPOModel::setParameters(const std::vector< VectorXf >& params) {
	params_ = params;
}
std::shared_ptr< LPOModelTrainer > ExhaustiveLPOModel::makeTrainer(const std::vector< std::shared_ptr< ImageOverSegmentation > >& ios, const std::vector< std::vector< Polygons > >& gt) const {
	return makeExhaustiveTrainer( *this, ios, gt );
}
std::shared_ptr< LPOModelTrainer > ExhaustiveLPOModel::makeTrainer(const std::vector< std::shared_ptr< ImageOverSegmentation > >& ios, const std::vector< RMatrixXs >& gt) const {
	return makeExhaustiveTrainer( *this, ios, gt );
}
