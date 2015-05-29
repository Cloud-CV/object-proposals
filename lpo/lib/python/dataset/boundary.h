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
#include <boost/python.hpp>
using namespace boost::python;

std::tuple<RMatrixXb,RMatrixXb> matchAny( const RMatrixXb & a, const RMatrixXb & b, double max_r );
std::tuple<RMatrixXb,RMatrixXb> matchBp( const RMatrixXb & a, const RMatrixXb & b, double max_r );
Vector4i evalBoundaryBinary(const RMatrixXb & d, const std::vector<RMatrixXb> & bnd, double max_r );
RMatrixXf evalBoundary( const RMatrixXf & d, const std::vector<RMatrixXb> & bnd, int nthres, double max_r );

std::vector<RMatrixXf> evalBoundaryAll( const std::vector<RMatrixXf> &ds, const std::vector< std::vector<RMatrixXb> > &bnds, int nthres, double max_r );
std::vector<RMatrixXf> evalSegmentBoundaryAll( const std::vector<RMatrixXf> &ds, const std::vector<RMatrixXs> &segs, int nthres, double max_r );
