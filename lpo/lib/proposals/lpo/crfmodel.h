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
#include "lpomodel.h"
#include "proposals/seed.h"
#include "crf/crf.h"
#include "util/rasterize.h"

class SegmentationOverlap;

class CRFModel: public LPOModel {
protected:
	std::vector<BinaryCRF> crfs_;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainerFromOverlap( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap > & gt ) const = 0;
public:
	virtual void setParameters( const std::vector<VectorXf> & params );
	virtual void load( std::istream & is );
	virtual void save( std::ostream & os ) const;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainer( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< std::vector<Polygons> > & gt ) const;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainer( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector<RMatrixXs> & gt ) const;
};

class GlobalCRFModel: public CRFModel {
protected:
	virtual std::shared_ptr<LPOModelTrainer> makeTrainerFromOverlap( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap > & gt ) const;
public:
	GlobalCRFModel();
	virtual std::vector<Proposals> propose( const ImageOverSegmentation & ios ) const;
};

class SeedCRFModel: public CRFModel {
protected:
	std::shared_ptr<SeedFunction> seed_;
	int max_seed_;
	virtual std::shared_ptr<LPOModelTrainer> makeTrainerFromOverlap( const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap > & gt ) const;
public:
	SeedCRFModel(const std::shared_ptr<SeedFunction> & seed = std::shared_ptr<SeedFunction>(), int max_seed=200);
	virtual std::vector<Proposals> propose( const ImageOverSegmentation & ios ) const;
	virtual void load( std::istream & is );
	virtual void save( std::ostream & os ) const;
};
