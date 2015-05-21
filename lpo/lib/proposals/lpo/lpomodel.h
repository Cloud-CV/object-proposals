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
#pragma once
#include <memory>
#include "proposals/proposal.h"
#include "util/rasterize.h"

class ImageOverSegmentation;

class LPOModelTrainer {
public:
	virtual ~LPOModelTrainer();
	
	// Fit a model to a specific sample
	virtual VectorXf fit( int sample ) const = 0;
	// Refit the model to a bunch of samples (pass in any latent varaibles that we might have, plus the previous parameters)
	virtual VectorXf refit( const VectorXi & samples, const std::vector<VectorXf> & latent_variables, const VectorXf & previous_parameter ) const = 0;
	
	// Generate proposals using 'parameter's on image im_id. The function returns a set of latent_variables and proposals
	virtual VectorXf proposeAndEvaluate( const VectorXf & parameter, std::vector<VectorXf> & latent_variables ) const = 0;
	
	// Average number of proposals per parameter
	virtual float averageProposalsPerParameter( const VectorXf & parameter ) const = 0;
	
	// Debug info
	virtual std::string name() const = 0;
};

class LPOModel {
public:
	virtual ~LPOModel();
	virtual void load( std::istream & is ) = 0;
	virtual void save( std::ostream & os ) const = 0;
	
	virtual std::vector<Proposals> propose( const ImageOverSegmentation & ios ) const = 0;
	
	// Training functions
	virtual void setParameters( const std::vector<VectorXf> & params ) = 0;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainer( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< std::vector<Polygons> > & gt ) const = 0;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainer( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector<RMatrixXs> & gt ) const = 0;
};

// An LPO Model Trainer for which an exhaustive list of parameters is known in advance
class ExhaustiveLPOModelTrainer: public LPOModelTrainer {
public:
	// List all possible parameters (instead of fitting)
	virtual std::vector<VectorXf> allParameters() const = 0;
};
class ExhaustiveLPOModel: public LPOModel {
protected:
	template<typename T>
	friend std::shared_ptr< ExhaustiveLPOModelTrainer > makeExhaustiveTrainer( const ExhaustiveLPOModel & that, const std::vector< std::shared_ptr< ImageOverSegmentation > >& ios, const std::vector< T >& gt );
	std::vector<VectorXf> all_params_, params_;
	virtual std::vector<Proposals> generateProposals( const ImageOverSegmentation & ios, const std::vector<VectorXf> & params ) const = 0;
public:
	ExhaustiveLPOModel( const std::vector<VectorXf> & all_params = std::vector<VectorXf>() );
	
	virtual void load( std::istream & is );
	virtual void save( std::ostream & os ) const;
	
	virtual std::vector<Proposals> propose( const ImageOverSegmentation & ios ) const;
	
	// Training functions
	virtual void setParameters( const std::vector<VectorXf> & params );
	virtual std::shared_ptr<LPOModelTrainer> makeTrainer( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< std::vector<Polygons> > & gt ) const;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainer( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector<RMatrixXs> & gt ) const;
};

void saveLPOModel( std::ostream & os, const std::shared_ptr<LPOModel> & model );
std::shared_ptr<LPOModel> loadLPOModel( std::istream & os );

class ModelRegister {
public:
	virtual const std::string & name() const = 0;
	virtual bool istype( const std::shared_ptr<LPOModel> & m ) const = 0;
	virtual std::shared_ptr<LPOModel> make() const = 0;
};
template<typename M> class ModelRegisterT: public ModelRegister {
protected:
	std::string name_;
public:
	ModelRegisterT( const std::string & n ):name_(n) {
	}
	virtual const std::string & name() const {
		return name_;
	}
	virtual bool istype( const std::shared_ptr<LPOModel> & m ) const {
		return (bool)std::dynamic_pointer_cast<M>(m);
	}
	virtual std::shared_ptr<LPOModel> make() const {
		return std::make_shared<M>();
	}
};

std::string modelName( const std::shared_ptr<LPOModel> & m );
void registerModel( const std::shared_ptr<ModelRegister> & r );
template<typename M> 
void registerModel( const std::string & n ) {
	registerModel( std::make_shared< ModelRegisterT<M> >(n) );
}
#define DEFINE_MODEL( M ) static int register_##M(){ registerModel<M>( #M ); return 0; } static int init_##M = register_##M()
