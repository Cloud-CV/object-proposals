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
#include "optimization.h"
#include "lbfgs.h"
// #include "lbfgsb.h"
#include <cstdio>
#include <iostream>

EnergyFunction::~EnergyFunction() {
}
namespace optimizePrivate {
static int _progress( void *instance, const lbfgsfloatval_t *x, const lbfgsfloatval_t *g, const lbfgsfloatval_t fx, const lbfgsfloatval_t xnorm, const lbfgsfloatval_t gnorm, const lbfgsfloatval_t step, int n, int k, int ls ) {
	printf("Iteration %d:\n", k);
	printf("  fx = %f, xnorm = %f, gnorm = %f, step = %f\n", fx, xnorm, gnorm, step );
	std::cout<<"  x = "<<VectorXf::Map(x,n).transpose()<<std::endl;
	std::cout<<"  g = "<<VectorXf::Map(g,n).transpose()<<std::endl;
	return 0;
}
static lbfgsfloatval_t _evaluate( void *instance, const lbfgsfloatval_t *x, lbfgsfloatval_t *g, const int n, const lbfgsfloatval_t step ) {
	const EnergyFunction * efun = static_cast<EnergyFunction*>(instance);
	if(!efun) {
		printf("No energy function to optimize! Giving up.\n");
		VectorXf::Map(g,n) = 0*VectorXf::Map(x,n);
		return 0;
	}
	float r=0;
	VectorXf::Map(g,n) = efun->gradient( VectorXf::Map(x,n), r );
	return r;
}
}

VectorXf minimizeLBFGS(const EnergyFunction &f, float & e, int verbose ) {
	using namespace optimizePrivate;

	VectorXf r = f.initialGuess();
	const int N = r.size();

	lbfgsfloatval_t fx;
	lbfgsfloatval_t *m_x = lbfgs_malloc(N);

	std::copy( r.data(), r.data()+N, m_x );

	lbfgs_parameter_t param;
	lbfgs_parameter_init( &param );
	param.max_iterations = 100;

	int ret = lbfgs(N, m_x, &fx, _evaluate, (verbose>1)?_progress:NULL, const_cast<EnergyFunction*>(&f), &param);

	/* Report the result. */
	if( verbose>0 ) {
		printf("L-BFGS optimization terminated with status code = %d\n", ret);
		printf("  fx = %f\n", fx);
		std::cout<<"  x = "<<VectorXf::Map(m_x,N).transpose()<<std::endl;
	}
	// Store the result and clean up
	e = fx;
	r = VectorXf::Map( m_x, N );
	lbfgs_free( m_x );
	return r;
}
VectorXf minimizeLBFGS( const EnergyFunction & f, int verbose ) {
	float tmp;
	return minimizeLBFGS( f, tmp, verbose );
}
float gradCheck( const EnergyFunction &f, const VectorXf &x, int verbose ) {
	const float EPS = 1e-3;

	float e;
	VectorXf g = f.gradient( x, e );
	VectorXf gg = 1*g;
	for( int i=0; i<x.size(); i++ ) {
		VectorXf d = VectorXf::Zero( x.size() );
		d[i] = 1;

		float e1 = 0, e2 = 0;
		f.gradient( x+EPS*d, e1 );
		f.gradient( x-EPS*d, e2 );
		gg[i] = (e1-e2)/(2*EPS);
	}
	float rel_e = ((g-gg).array().abs() / (g.array().abs()+gg.array().abs()).max(1)).maxCoeff();
// 	float rel_e = (g-gg).array().abs().maxCoeff() / (g.array().abs()+gg.array().abs()+1e-3).maxCoeff();
	if( verbose ) {
		printf("Grad test  %f  %f\n", (g-gg).norm(), rel_e);
		std::cout<<"real  = "<<g.transpose()<<std::endl;
		std::cout<<"fdiff = "<<gg.transpose()<<std::endl;
		std::cout<<"rel e = "<<((g-gg).array().abs() / (g.array().abs()+gg.array().abs()+1e-3)).transpose()<<std::endl;
	}
	return rel_e;
}
float gradCheck( const EnergyFunction &f, int verbose ) {
	return gradCheck( f, f.initialGuess(), verbose );
}
