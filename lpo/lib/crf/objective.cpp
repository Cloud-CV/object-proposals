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
#include "objective.h"
#include "util/qp.h"
#include "util/util.h"
#include <iostream>

static const int verbose = 0;
static const bool pairwise_positive = true;

OneSlackObjective::OneSlackObjective( const float C ):C_(C) {
}

std::tuple<VectorXf,VectorXf> OneSlackObjective::optimize( const std::vector<ParameterConstraint> & constraints, float * objective_value ) const {
	// Unless I find time to code up an interior point QP solver
	// we need a strictly positive definite QP here. This is why we add
	// a quadratic penalty EPS on the slack
	const float EPS = 1e-4;
	// Floating point type
	typedef double T;
	// Should we constrain the pairwise term to be positive?

	eassert( constraints.size() > 0 );

	const int Nu = constraints[0].du.size();
	const int Np = constraints[0].dp.size();
	const int Ns = 1;
	const int N = Nu + Np + Ns;
	const int Nc = 1 + constraints.size() + (pairwise_positive?Np:0);

	// Setup the Quadratic Objective
	const float SQRT_EPS = sqrt(EPS);
	RMatrixX<T> Q = RMatrixX<T>::Identity( N, N );
	VectorX<T> c = VectorX<T>::Zero( N );
	c[N-1] = C_ / SQRT_EPS;

	// Setup the constraints
	RMatrixX<T> A = RMatrixX<T>::Zero( Nc, N );
	VectorX<T> b = VectorX<T>::Zero( Nc );
	int nc = 0;
	for( auto c: constraints ) {
		A.row(nc).head(Nu)       = c.du.cast<T>();
		A.row(nc).segment(Nu,Np) = c.dp.cast<T>();
		A(nc,N-1) = -1.0 / SQRT_EPS;
		b[nc] = -c.loss;
		nc++;
	}
	// Add a positivity constraint on the pairwise term
	if( pairwise_positive )
		for( int i=0; i<Np; i++ )
			A(nc++,Nu+i) = -1;
	// Add a positivity constraint on the slack variable
	A(nc,N-1) = -1;

	// Compute the parameter vector
	VectorX<T> x = qp( Q, c, A, b );
	if (pairwise_positive)
		x.segment(Nu,Np).array() *= (x.segment(Nu,Np).array()>=0).cast<T>();

	if( objective_value )
		*objective_value = (0.5*Q*x+c).dot(x);
	if (verbose>1) printf("  Objective %f  +  %f\n", 0.5*(Q*x).dot(x), x.dot(c) );
	if (verbose>0) std::cout<<" S = "<<x.tail(Ns).transpose()/SQRT_EPS<<std::endl;
	return std::make_tuple( x.head(Nu).cast<float>(), x.segment(Nu,Np).cast<float>() );
}
std::tuple<VectorXf,VectorXf> OneSlackObjective::optimize( const std::vector< std::vector<ParameterConstraint> >& constraints, float * objective_value ) const {
	std::vector< ParameterConstraint > cc;
	for( auto c: constraints )
		cc.insert( c.begin(), c.end(), cc.end() );
	return optimize( cc, objective_value );
}


NSlackObjective::NSlackObjective( const float C ):C_(C) {
}
std::tuple<VectorXf,VectorXf> NSlackObjective::optimize( const std::vector< std::vector<ParameterConstraint> >& constraints, float * objective_value ) const {
	// Unless I find time to code up an interior point QP solver
	// we need a strictly positive definite QP here. This is why we add
	// a quadratic penalty EPS on the slack
	const float EPS = 1e-4;
	// Floating point type
	typedef float T;
	// Should we constrain the pairwise term to be positive?

	eassert( constraints.size() > 0 );
	eassert( constraints[0].size() > 0 );

	const int Nu = constraints[0][0].du.size();
	const int Np = constraints[0][0].dp.size();
	const int Ns = constraints.size();
	const int N = Nu + Np + Ns;
	int Nc = Ns + (pairwise_positive?Np:0);
	for( auto c: constraints )
		Nc += c.size();

	// Setup the Quadratic Objective
	const float SQRT_EPS = sqrt(EPS);
	RMatrixX<T> Q = RMatrixX<T>::Identity( N, N );
	VectorX<T> c = VectorX<T>::Zero( N );
	c.tail(Ns).setConstant( C_ / N / SQRT_EPS );

	// Setup the constraints
	RMatrixX<T> A = RMatrixX<T>::Zero( Nc, N );
	VectorX<T> b = VectorX<T>::Zero( Nc );
	int nc = 0, ns = Nu+Np;
	for( auto c: constraints ) {
		for( auto cc: c ) {
			A.row(nc).head(Nu)       = cc.du.cast<T>();
			A.row(nc).segment(Nu,Np) = cc.dp.cast<T>();
			A(nc,ns) = -1.0 / SQRT_EPS;
			b[nc] = -cc.loss;
			nc++;
		}
		// Add a positivity constraint on the slack variable
		A(nc,ns) = -1.0;
		nc++;
		ns++;
	}
	// Add a positivity constraint on the pairwise term
	if( pairwise_positive )
		for( int i=0; i<Np; i++ )
			A(nc++,Nu+i) = -1;

	// Compute the parameter vector
	VectorX<T> x = qp( Q, c, A, b );
	if (pairwise_positive)
		x.segment(Nu,Np).array() *= (x.segment(Nu,Np).array()>=0).cast<T>();

	if( objective_value )
		*objective_value = (0.5*Q*x+c).dot(x);
	if (verbose>1) printf("  Objective %f  +  %f\n", 0.5*(Q*x).dot(x), x.dot(c) );
	if (verbose>0) std::cout<<" S = "<<x.tail(Ns).transpose()/SQRT_EPS<<std::endl;
	return std::make_tuple( x.head(Nu).cast<float>(), x.segment(Nu,Np).cast<float>() );
}
