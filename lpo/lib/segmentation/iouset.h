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
#include <vector>
#include "util/eigen.h"
#include "util/graph.h"

typedef Matrix<short,4,1> Vector4s;
class OverSegmentation;
class ImageOverSegmentation;
class IOUSet {
protected:
	std::vector<int> parent_, left_, right_;
	VectorXu area_;
	std::vector<VectorXu> set_;
	
	// Datastructures that speed things up
	std::multimap<unsigned int,short> area_map_;
	std::vector<Vector4s> spix_box_;
	std::vector<Vector4s> bbox_;
	VectorXu sumTree( const VectorXu & area_map ) const;
	VectorXu computeTree( const VectorXb & p ) const;
	
	void addTree( const VectorXu & v );
	bool intersectsTree( const VectorXu & v, const Vector4s & bbox, float max_iou ) const;
	bool intersectsTree( const VectorXu & v, float max_iou ) const;
	bool cmpIOU( const VectorXu & a, const VectorXu & b, float max_iou ) const;
	void init( const RMatrixXs & s );
public:
	IOUSet( const RMatrixXs & s );
	IOUSet( const ImageOverSegmentation & os );
	
	bool addIfNotIntersects( const VectorXb & p, float max_iou );
	void add( const VectorXb & p );
	bool intersects( const VectorXb & p, float max_iou ) const;
	bool intersects( const VectorXu & area, const Vector4s & bbox, float max_iou ) const;
	
	Vector4s computeBBox( const VectorXb & v ) const;
};
