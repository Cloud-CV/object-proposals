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
#include "util/eigen.h"
#include "util/geodesics.h"
#include <vector>
#include <memory>

class ImageOverSegmentation;
class SeedFeature {
protected:
	friend class SeedFeatureFactory;
	friend RowVectorXf operator*( const RowVectorXf & o, const SeedFeature & f );
	RMatrixXf static_f_;
	RMatrixXf dynamic_f_;
	RMatrixXf pos_, col_, var_, min_dist_;
	int n_;
	std::vector<GeodesicDistance> gdist_;
	
	SeedFeature( const ImageOverSegmentation & ios, const VectorXf & obj_param );
	static RMatrixXf computeObjFeatures( const ImageOverSegmentation & ios );
public:
	void update( int n );
	int cols() const;
	int rows() const;
	VectorXf operator*( const VectorXf & o ) const;
	operator RMatrixXf() const;
};
class SeedFeatureFactory {
protected:
	VectorXf param_;
public:
	SeedFeature make( const ImageOverSegmentation & ios ) const;
	void train( const std::vector< std::shared_ptr<ImageOverSegmentation> > &ios, const std::vector<VectorXs> & lbl );
	void load( std::istream & is );
	void save( std::ostream & os ) const;
};
RowVectorXf operator*( const RowVectorXf & o, const SeedFeature & f );
