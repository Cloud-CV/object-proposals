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
#include "lpo/lpomodel.h"

class SeedFunction;
class LPO {
protected:
	std::vector< std::shared_ptr<LPOModel> > models_;
	void train(const std::vector< std::shared_ptr<LPOModelTrainer> >& trainers, int n_samples, const float f0=0.1 );
public:
	// Model setup
	void addGlobal();
	void addSeed( std::shared_ptr<SeedFunction> seed, int max_seed );
	void addGBS(const std::string & color_space, const std::vector<float> & params, int max_size=1000 );
	
	// Proposal generation
	std::vector<Proposals> propose( const ImageOverSegmentation & ios, float max_iou=0.9, int model_id=-1, bool box_nms=false ) const;
	
	// Training functions
	void train( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector<RMatrixXs> & gt, const float f0=0.1 );
	void train( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< std::vector<Polygons> > & gt, const float f0=0.1 );
	
	int nModels() const;
	std::vector<std::string> modelTypes() const;
	
	// Saving and loading functions
	void save( std::ostream & os ) const;
	void load( std::istream & is );
	void save( const std::string & fn ) const;
	void load( const std::string & fn );
};
