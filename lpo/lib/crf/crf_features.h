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
#include "crf.h"

enum UnaryFeatureType {
	// Global features
	CONSTANT = (1<<0),
	POSITION = (1<<1),
	COLOR    = (1<<2),
	BG_COLOR = (1<<3),
	COLOR_SQ = (1<<4),
	COLOR_DF = (1<<5),
	GEO_BND  = (1<<6),
	// Seed based features
	SEED_INDICATOR= (1<<10),
	GEO_SEED      = (1<<11),
	COLOR_SEED    = (1<<12),
	COLOR_SEED_SQ = (1<<13),
	COLOR_SEED_DF = (1<<14),
};

const int DEFAULT_STATIC_FEATURE = CONSTANT | POSITION | COLOR | BG_COLOR | COLOR_DF | GEO_BND;
const int DEFAULT_SEED_FEATURE = DEFAULT_STATIC_FEATURE | SEED_INDICATOR | GEO_SEED;// | COLOR_SEED_DF;

class ImageOverSegmentation;
class StaticBinaryCRFFeatures: public BinaryCRFFeatures {
protected:
	Edges graph_;
	RMatrixXf unary_, pairwise_;
	int which_;
	virtual void makeUnary( const ImageOverSegmentation & ios );
	virtual void makePairwise( const ImageOverSegmentation & ios );
	friend class CachedSeedBinaryCRFFeatures;
	StaticBinaryCRFFeatures( const RMatrixXf & unary, const Edges & graph, const RMatrixXf & pairwise, int which );
public:
	StaticBinaryCRFFeatures( const ImageOverSegmentation & ios, int which = DEFAULT_STATIC_FEATURE );
	virtual const RMatrixXf & unary() const;
	virtual const RMatrixXf & pairwise() const;
	virtual const Edges & graph() const;
};
struct GeodesicDistance;
class SeedBinaryCRFFeatures: public StaticBinaryCRFFeatures {
protected:
	int d_seed_;
	std::shared_ptr<GeodesicDistance> gdist0_, gdist1_, gdist2_, gdist3_;
	RMatrixXf mean_color_;
	virtual void updateUnary( RMatrixXf & f, int s ) const;
public:
	SeedBinaryCRFFeatures( const ImageOverSegmentation & ios, int which = DEFAULT_SEED_FEATURE );
	virtual void update( int s );
};
class CachedSeedBinaryCRFFeatures: public SeedBinaryCRFFeatures {
protected:
	std::shared_ptr< std::vector<RMatrixXf> > cache_;
	VectorXi seed_to_cache_id_;
	virtual void updateUnary( RMatrixXf & f, int s ) const;
public:
	CachedSeedBinaryCRFFeatures( const ImageOverSegmentation & ios, const VectorXi & seeds, int which = DEFAULT_SEED_FEATURE );
	std::shared_ptr<StaticBinaryCRFFeatures> get( int s ) const;
};
