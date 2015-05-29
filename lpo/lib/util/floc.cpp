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
#include "floc.h"
#include <iostream>
#include <queue>
#include <set>
#include "util/util.h"
#include <floc/facloc_JMS.h>
#include <floc/facloc_LOCAL.h>

float Floc::energy( const VectorXf & f, const RMatrixXf & C, const VectorXb & x ) {
	VectorXf xf = x.cast<float>();
	return xf.dot(f) + RowVectorXf((C.colwise()+(1.f-xf.array()).matrix()*1e10).colwise().minCoeff()).array().sum();
}

namespace flocprivate{
struct Nd {
	float w;
	int i;
	Nd( float w, int i ):w(w),i(i){}
	bool operator<(const Nd & o) const {
		if (w == o.w)
			return i < o.i;
		return w < o.w;
	}
};
}

VectorXb Floc::greedy( const VectorXf & f, const RMatrixXf & C ) {
	using namespace flocprivate;
	const int N = f.size(), M = C.cols();
	assert( C.rows() == N );
	VectorXb x = VectorXb::Zero( N );

	// Best currently placed facility
	const float max_c = C.maxCoeff()+f.maxCoeff() + 10;
	RowVectorXf min_c = RowVectorXf::Constant(M,max_c), min_c2 = RowVectorXf::Constant(M,max_c);

	std::vector< std::set<Nd> > ordered_C( M );

	while(1) {
		// See if placing a new facility could help
		VectorXf gain_add = -f - VectorXf( ( C.rowwise() - min_c ).array().min( 0.f ).rowwise().sum() );
		VectorXf gain_rem = f + VectorXf( ( C.rowwise() - min_c2 ).array().min( 0.f ).rowwise().sum() );
		int next_add = 0, next_rem = 0;
		float best_gain_add = (gain_add.array()*(1-x.cast<float>().array())).maxCoeff( &next_add );
		float best_gain_rem = (gain_rem.array()*x.cast<float>().array()).maxCoeff( &next_rem );
		if( best_gain_add <= 0 && best_gain_rem <= 0 )
			break;
		int next = best_gain_add < best_gain_rem ? next_rem : next_add;

		x[next] = !x[next];
		for( int j=0; j<M; j++ ) {
			// Add or remove the next element
			if( x[next] )
				ordered_C[j].insert( Nd(C(next,j),next) );
			else
				ordered_C[j].erase( Nd(C(next,j),next) );

			// And find the next biggest element
			eassert( ordered_C[j].size()>=1 );
			auto it = ordered_C[j].begin();
			min_c[j] = it->w;
			min_c2[j] = ordered_C[j].size() > 1 ? (++it)->w : max_c;
		}
	}
	return x;
}
struct QE {
	float w;
	int i;
	QE( float w, int i ):w(w),i(i){}
	bool operator<( const QE & o ) const {
		return w < o.w;
	}
};
VectorXb Floc::jms( const VectorXf & f, const RMatrixXf & C ) {
	eassert( f.size() == C.rows() );
	VectorXd fd = f.cast<double>();
	RMatrixXd Cd = C.cast<double>();
	VectorXi cn = VectorXi::Zero( C.cols() );
	double e;
	UNCAP_FACILITY_LOCATION_JMS( fd.data(), Cd.data(), C.rows(), C.cols(), cn.data(), e );
	VectorXb r = VectorXb::Zero( f.size() );
	for( int i=0; i<cn.size(); i++ )
		r[ cn[i] ] = 1;
	return r;
}
VectorXb Floc::myz( const VectorXf & f, const RMatrixXf & C ) {
	eassert( f.size() == C.rows() );
	VectorXd fd = f.cast<double>();
	RMatrixXd Cd = C.cast<double>();
	VectorXi cn = VectorXi::Zero( C.cols() );
	double e;
	UNCAP_FACILITY_LOCATION_MYZ( fd.data(), Cd.data(), C.rows(), C.cols(), cn.data(), e );
	VectorXb r = VectorXb::Zero( f.size() );
	for( int i=0; i<cn.size(); i++ )
		r[ cn[i] ] = 1;
	return r;
}
VectorXb Floc::local( const VectorXf & f, const RMatrixXf & C ) {
	eassert( f.size() == C.rows() );
	VectorXd fd = f.cast<double>();
	RMatrixXd Cd = C.cast<double>();
	VectorXi cn = VectorXi::Zero( C.cols() );
	double e;
	UNCAP_FACILITY_LOCATION_LOCAL( fd.data(), Cd.data(), C.rows(), C.cols(), cn.data(), e );
	VectorXb r = VectorXb::Zero( f.size() );
	for( int i=0; i<cn.size(); i++ )
		r[ cn[i] ] = 1;
	return r;
}
VectorXb Floc::scaledLocal( const VectorXf & f, const RMatrixXf & C ) {
	eassert( f.size() == C.rows() );
	VectorXd fd = f.cast<double>();
	RMatrixXd Cd = C.cast<double>();
	VectorXi cn = VectorXi::Zero( C.cols() );
	double e;
	UNCAP_FACILITY_LOCATION_SCALED_LOCAL( fd.data(), Cd.data(), C.rows(), C.cols(), cn.data(), e );
	VectorXb r = VectorXb::Zero( f.size() );
	for( int i=0; i<cn.size(); i++ )
		r[ cn[i] ] = 1;
	return r;
}
VectorXb Floc::tabu( const VectorXf & f, const RMatrixXf & C ) {
	eassert( f.size() == C.rows() );
	VectorXd fd = f.cast<double>();
	RMatrixXd Cd = C.cast<double>();
	VectorXi cn = VectorXi::Zero( C.cols() );
	double e;
	UNCAP_FACILITY_LOCATION_TABU( fd.data(), Cd.data(), C.rows(), C.cols(), cn.data(), e );
	VectorXb r = VectorXb::Zero( f.size() );
	for( int i=0; i<cn.size(); i++ )
		r[ cn[i] ] = 1;
	return r;
}
