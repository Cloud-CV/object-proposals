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
#include "crf.h"
#include "loss.h"
#include "objective.h"
#include "util/util.h"
#include <ibfs/ibfs.h>
#include <iostream>
#include <random>
#ifdef _OPENMP
# include <omp.h>
#endif

const int MAX_INT_FLOAT = (1<<20);
static int verbose = 0;

// #define ONE_SLACK

BinaryCRFFeatures::~BinaryCRFFeatures(){
}
TrainingLoss::~TrainingLoss(){
}
float TrainingLoss::evaluate( const VectorXf & X, const VectorXf & gt ) const {
	return evaluate( ( (gt.array()==1).cast<float>()*   X.array()  ).sum(), ( (gt.array()==0).cast<float>()*   X.array()  ).sum(),
					 ( (gt.array()==1).cast<float>()*(1-X.array()) ).sum(), ( (gt.array()==0).cast<float>()*(1-X.array()) ).sum() );
}

MaxMarginObjective::~MaxMarginObjective(){
}
BinaryCRF::BinaryCRF() {

}
bool BinaryCRF::operator==(const BinaryCRF & o) const {
	return unary_ == o.unary_ && pairwise_ == o.pairwise_;
}
VectorXf BinaryCRF::inference( const VectorXf & u, const Edges & g, const VectorXf & w, float * e ) {
	const int N = u.rows();
	const float FLOAT_TO_INT_SCALE = MAX_INT_FLOAT / std::max(u.array().abs().maxCoeff(),w.size()>0?w.array().abs().maxCoeff():0);
	IBFSGraph max_flow;
	max_flow.initSize( N, g.size() );

	int rE = 0;
	for( int i=0; i<N; i++ ) {
		if (u[i] > 0)
			max_flow.addNode( i, 0, FLOAT_TO_INT_SCALE*u[i] );
		else if (u[i] < 0) {
			max_flow.addNode( i, -FLOAT_TO_INT_SCALE*u[i], 0 );
			rE += FLOAT_TO_INT_SCALE*u[i];
		}
	}
	for( int i=0; i<g.size(); i++ )
		max_flow.addEdge( g[i].a, g[i].b, FLOAT_TO_INT_SCALE*w[i], FLOAT_TO_INT_SCALE*w[i] );
	max_flow.initGraph();
	rE += max_flow.computeMaxFlow();
	VectorXf r = VectorXf::Zero( N );
	for( int i=0; i<N; i++ )
		r[i] = (float)max_flow.isNodeOnSrcSide( i );
	if( e ) *e = rE / FLOAT_TO_INT_SCALE;
	return r;
}

float BinaryCRF::energy( const VectorXf & l, const VectorXf & u, const Edges & g, const VectorXf & w ) {
	int N = u.rows();
	float E = 0;
	for( int i=0; i<N; i++ )
		E += l[i]*u[i];
	for( int i=0; i<g.size(); i++ )
		E += w[i]*fabs(l[g[i].a] - l[g[i].b]);
	return E;
}
VectorXf BinaryCRF::map( const std::shared_ptr<BinaryCRFFeatures> & f, float * e ) const {
	if( unary_.size() != f->unary().cols() || pairwise_.size() != f->pairwise().cols() )
		throw std::invalid_argument( "You need to train the CRF first and use the same features during inference!" );
	return inference( f->unary()*unary_, f->graph(), f->pairwise()*pairwise_, e );
}
RMatrixXf BinaryCRF::diverseMBest(const std::shared_ptr< BinaryCRFFeatures > &f, int M, const TrainingLoss &loss) const {
	if( unary_.size() != f->unary().cols() || pairwise_.size() != f->pairwise().cols() )
		throw std::invalid_argument( "You need to train the CRF first and use the same features during inference!" );
	VectorXf u = f->unary()*unary_, p = f->pairwise()*pairwise_;
	const Edges & g = f->graph();
	RMatrixXf r( u.size(), M );
	for( int i=0; i<M; i++ ) {
		VectorXf x;
		r.col(i) = x = inference( u, g, p );

		// Subtract the current loss
		const int NP = x.cast<int>().array().sum();
		const int NN = x.size() - NP;
		const float l0 = loss.evaluate( NP  , 0, 0, NN );
		const float lp = loss.evaluate( NP-1, 0, 1, NN );
		const float ln = loss.evaluate( NP  , 1, 0, NN-1 );
		u -= (x.array()>0).select(VectorXf::Constant(x.size(),l0-lp),ln-l0);
	}
	return r;
}
float BinaryCRF::e( const VectorXf & s, const std::shared_ptr<BinaryCRFFeatures> & f ) const {
	if( unary_.size() != f->unary().cols() || pairwise_.size() != f->pairwise().cols() )
		throw std::invalid_argument( "You need to train the CRF first and use the same features during inference!" );
	return energy( s, f->unary()*unary_, f->graph(), f->pairwise()*pairwise_ );
}

//////////////////////////////////////////////////
//////////////////// Training ////////////////////
//////////////////////////////////////////////////

VectorXf BinaryCRF::inferenceWithIOU( const VectorXf & u, const Edges & g, const VectorXf & w, const VectorXs & l, float k ) {
	// TODO: Handle missing data
	const float EPS = 1e-3, EPS2 = 1e-3;
	VectorXf a = (l.array()==1).cast<float>(), b = (l.array()==0).cast<float>();
	VectorXf best_X;
	float best_e = 1e5;
	int neval=0, niter=0;
	// Evaluate all interesting IoU values
	for( float l=1; l>0; ) {
		// TODO: v1 is might be wrong!!
		float v0=0, v1 = b.dot(b)+1000;
		// TODO: Doing bisectin twice is inefficient figure out how to make this faster!!!!

		// Bisection search [instead of a parametric cut]
		// Solve for E(X) s.t. IoU(X) < l
		while( v0+EPS<v1 ) {
			float v = (v0+v1)/2.0;
			VectorXf uu = u + v*a - v*l*b;
			VectorXf X = inference( uu, g, w );
			neval++;

			float dv = a.dot(X)-l*a.dot(a)-l*b.dot(X);

			if( dv > 0 )
				v0 = v;
			else// if ( dv < 0 )
				v1 = v;
		}
		if( verbose>3 ) printf("%f %f\n", v0, v1 );
		niter++;

		// Compute X s.t. IoU(X) < l
		VectorXf uu = u + v1*a - v1*l*b;
		VectorXf X = inference( uu, g, w );

		// Compute the energy of the labeling
		float e = energy( X, u, g, w ) + k*a.dot(X)/(a.dot(a)+b.dot(X));
		if( e < best_e ) {
			best_e = e;
			best_X = X;
		}
		if( verbose>3 )
			printf("[%f]   %f -> %f    %f [%f] [%f %f]\n", a.dot(a), l, a.dot(X)/(a.dot(a)+b.dot(X)), energy( X, u, g, w ), e, v0, v1 );
		// and try a tighter constraint
		l = a.dot(X)/(a.dot(a)+b.dot(X))-EPS2;
	}
	// Handle l=0
	VectorXf uu = u + b.dot(b)*a;
	VectorXf X = inference( uu, g, w );
	float e = energy( X, u, g, w ) + k*a.dot(X)/(a.dot(a)+b.dot(X));
	if( e < best_e ) {
		best_e = e;
		best_X = X;
	}

	if( verbose>3 ) {
		printf("SOLVED %f   %f   [%f + %f]   %f\n", best_e, energy( best_X, u, g, w ) + a.dot(best_X)/(a.dot(a)+b.dot(best_X)), energy( best_X, u, g, w ), a.dot(best_X)/(a.dot(a)+b.dot(best_X)), energy( l.cast<float>(), u, g, w )-(energy( best_X, u, g, w ) + a.dot(best_X)/(a.dot(a)+b.dot(best_X))) );
		printf("%f %f %f %f\n", a.dot(best_X), b.dot(best_X), best_X.dot(best_X), a.dot(a) );
	}
	return best_X;
}
VectorXf BinaryCRF::inferenceWithLoss( const VectorXf & u, const Edges & g, const VectorXf & w, const VectorXs & l, const TrainingLoss & loss ) {
	if (!loss.isLinear()) {
		if( dynamic_cast<const JaccardLoss*>(&loss) )
			return inferenceWithIOU( u, g, w, l, dynamic_cast<const JaccardLoss&>(loss).w() );
		throw std::invalid_argument( "For now only linear or IoU losses are supported!" );
	}

	// Find the linear place of the loss
	const int NP = l.cast<int>().array().sum();
	const int NN = l.size() - NP;
	const float l0 = loss.evaluate( NP  , 0, 0, NN );
	const float lp = loss.evaluate( NP-1, 0, 1, NN );
	const float ln = loss.evaluate( NP  , 1, 0, NN-1 );
	VectorXf ll = (l.array()>0).select(VectorXf::Constant(l.size(),l0-lp),(l.array()==0).cast<float>()*(ln-l0));

	return inference( u - ll, g, w ).cast<float>();
}
static VectorXf computeUnaryF( const VectorXf & s, const BinaryCRFFeatures & f ) {
	return f.unary().transpose() * s.cast<float>();
}
static VectorXf computePairwiseF( const VectorXf & s, const BinaryCRFFeatures & f ) {
	const RMatrixXf & pf = f.pairwise();
	const Edges & g = f.graph();
	VectorXf r = VectorXf::Zero( pf.cols() );
	for( int i=0; i<(int)g.size(); i++ )
		r += fabs(s[ g[i].a ]-s[ g[i].b ])*pf.row(i).transpose();
	return r;
}

ParameterConstraint::ParameterConstraint():loss(0) {
}
float ParameterConstraint::slack( const VectorXf & unary, const VectorXf & pairwise ) const {
	return du.dot( unary ) + dp.dot( pairwise ) + loss;
}
ParameterConstraint & ParameterConstraint::operator+=( const ParameterConstraint & o ) {
	loss += o.loss;
	if( !du.size() ) du = o.du;
	else du += o.du;
	if( !dp.size() ) dp = o.dp;
	else dp += o.dp;
	return *this;
}
ParameterConstraint & ParameterConstraint::operator*=( const float & o ) {
	loss *= o;
	du *= o;
	dp *= o;
	return *this;
}


ParameterConstraint BinaryCRF::generateConstraint( const BinaryCRFFeatures & f, const VectorXs & l, const TrainingLoss & loss ) const {
	// Find the most violated assignment X
	VectorXf u = f.unary()*unary_;
	VectorXf p = f.pairwise()*pairwise_;
	VectorXf X = inferenceWithLoss( u, f.graph(), p, l, loss );

	// This should be 0, but just to be on the save side
	const VectorXf lf = l.cast<float>();
	const float NP = lf.array().sum(), NN = l.size()-NP;
	const float loss0 = loss.evaluate( NP, 0, 0, NN );

	// Compute a new hyperplane
	ParameterConstraint r;
	r.du   = computeUnaryF   ( lf, f ) - computeUnaryF   ( X, f );
	r.dp   = computePairwiseF( lf, f ) - computePairwiseF( X, f );
	r.loss = loss.evaluate( X, lf ) - loss0;

	if (verbose>3)
		printf("%f + %f + %f <= 0 [%f]\n", r.du.dot(unary_), r.dp.dot(pairwise_), r.loss, r.du.dot(unary_) + r.dp.dot(pairwise_) + r.loss );

	return r;
}

bool BinaryCRF::isTrained() const {
	return unary_.size() > 0 && pairwise_.size() > 0;
}
void BinaryCRF::train( const std::shared_ptr<BinaryCRFFeatures> & f, const VectorXs & l, const TrainingLoss & loss ) {
	train( std::vector< std::shared_ptr<BinaryCRFFeatures> >( 1, f ), std::vector<VectorXs>( 1, l ), loss );
}
void BinaryCRF::train( const std::shared_ptr<BinaryCRFFeatures> & f, const VectorXs & l ) {
	train( std::vector< std::shared_ptr<BinaryCRFFeatures> >( 1, f ), std::vector<VectorXs>( 1, l ) );
}
void BinaryCRF::train( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l
					  ) {
	train( f, l, HammingLoss() );
}
void BinaryCRF::train( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l, const TrainingLoss & loss ) {
	if( f.size() > 2000 ) {
		// Subsample the training data, to make the trainNSlack faster
		std::vector< std::shared_ptr<BinaryCRFFeatures> > ff;
		std::vector< VectorXs > ll;
		std::mt19937 rand;
		for( int i=0; i<(int)f.size(); i++ ) {
			if (rand()%f.size() < 1900) {
				ff.push_back( f[i] );
				ll.push_back( l[i] );
			}
		}
		trainNSlack( ff, ll, loss );
	}
	else
		trainNSlack( f, l, loss );
}
void BinaryCRF::train1Slack( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l, const TrainingLoss & loss ) {
	// NOTE: There is probably a bug somewhere in here
	printf("1 slack\n");
	const int MAX_ITER = 1000;
	const int RETIREMENT_AGE = 50;
	const float EPS = 1e-2;
	const int N = f.size();
#ifdef _OPENMP
	const int N_THREAD = std::min( (N+4)/5, omp_get_max_threads() );
#endif
	eassert( N == l.size() );
	eassert( N > 0 );

	OneSlackObjective objective( 100.0 );
	Timer t; t.print_on_exit_ = false;

	// Initialize the parameters
	unary_ = VectorXf::Zero( f[0]->unary().cols() );
	pairwise_ = VectorXf::Zero( f[0]->pairwise().cols() );
	// Strat training
	std::vector< ParameterConstraint > constraints, cached_constraint(N);
	std::vector< int > age;
	float last_slack = 0;
	int niter=0;
	for( niter=0; niter<MAX_ITER; niter++ ) {
		t.tic();
		// Collect a bunch of (new) constraints
		t.tic();
		ParameterConstraint sc;
#pragma omp parallel for num_threads(N_THREAD)
		for( int i=0; i<N; i++ ) {
			if (!niter || cached_constraint[i].slack(unary_,pairwise_)+EPS < last_slack)
				cached_constraint[i] = generateConstraint( *f[i], l[i], loss );
#pragma omp critical
			sc += cached_constraint[i];
		}
		sc *= 1.0 / N;
		t.toc("Const Generation");
		float best_slack = -1e10;
		for( auto c: constraints )
			best_slack = std::max( best_slack, c.slack( unary_, pairwise_ ) );
		const float new_slack = sc.slack( unary_, pairwise_ );

		if( new_slack <= best_slack+EPS )
			break;

		constraints.push_back( sc );
		age.push_back( 0 );
		t.toc("Slack comp");

		// Solve for the parameters
		float o_val = 0;
		std::tie(unary_,pairwise_) = objective.optimize( constraints, &o_val );
		t.toc("QP");

		last_slack = sc.slack( unary_, pairwise_ );
		// Retire old constraints
		int j=0;
		for( int i=0; i<constraints.size(); i++ ) {
			float s = constraints[i].slack( unary_, pairwise_ );
			age[i] += 1;
			if( s >= last_slack-EPS ) age[i] = 0;
			if( age[i] < RETIREMENT_AGE ) {
				age[j] = age[i];
				constraints[j] = constraints[i];
				j++;
			}
		}
		age.resize(j);
		constraints.resize(j);
		t.toc("retirement");

		if( verbose > 2 ){
			float e2=0;
#pragma omp parallel for num_threads(N_THREAD)
			for( int i=0; i<N; i++ ) {
				VectorXf X = map( f[i] );
				const float ls = loss.evaluate( X, l[i].cast<float>() );
#pragma omp atomic
				e2 += ls;
			}
			printf("[%d] loss = %0.3f .. %0.3f [%f]\n",niter, sc.loss, e2 / N, new_slack );
		}

		if( verbose > 1 )
			printf(" Optimized to %f  [%f]\n\n", sc.loss, o_val );
	}
	if( verbose > 0 )
		printf("The algorithm converged after %d iterations\n", niter);
	if( verbose > 1 ) {
		std::cout<<"  unary    = "<<unary_.transpose()<<std::endl;
		std::cout<<"  pairwise = "<<pairwise_.transpose()<<std::endl;
		printf("\n");
	}
}
void BinaryCRF::trainNSlack( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l, const TrainingLoss & loss ) {
	const int MAX_ITER = 200;
	const float EPS = 1e-2;
	const int N = f.size();
#ifdef _OPENMP
	const int N_THREAD = std::min( (N+4)/5, omp_get_max_threads() );
#endif
	eassert( N == l.size() );
	eassert( N > 0 );

	NSlackObjective objective( 100 );
//	Timer t;

	// Initialize the parameters
	unary_ = VectorXf::Zero( f[0]->unary().cols() );
	pairwise_ = VectorXf::Zero( f[0]->pairwise().cols() );

	std::vector< std::vector< ParameterConstraint > > constraints(N);
	// Strat training
	int niter=0;
	float e1=0;
	for( niter=0; niter<MAX_ITER; niter++ ) {
		// Collect a bunch of (new) constraints
		int new_constraints = 0;
		e1 = 0;
		float sum_loss = 0;
#pragma omp parallel for num_threads(N_THREAD)
		for( int i=0; i<N; i++ ) {
//			t.tic();
			ParameterConstraint c = generateConstraint( *f[i], l[i], loss );
//			t.toc("Const Generation");

			float best_slack = -1e10;
			for( auto cc: constraints[i]  )
				best_slack = std::max( best_slack, cc.slack( unary_, pairwise_ ) );
			e1 += best_slack;
			sum_loss += c.loss;
			const float new_slack = c.slack( unary_, pairwise_ );
			if( new_slack > best_slack+EPS ) {
				constraints[i].push_back( c );
				new_constraints++;
			}
//			t.toc("Slack comp");
		}
		if( verbose > 2 ){
			float e2=0;
#pragma omp parallel for num_threads(N_THREAD)
			for( int i=0; i<N; i++ ) {
				VectorXf X = map( f[i] );
				const float ls = loss.evaluate( X, l[i].cast<float>() );
#pragma omp atomic
				e2 += ls;
			}
			printf("[%d] loss = %0.3f .. %0.3f [%f]\n",niter, sum_loss / N, e2 / N, e1 / N );
		}
//		printf("%d / %d iterations\n", new_constraints, MAX_ITER );
		if( !new_constraints )
			break;
		// Solve for the parameters
		float o_val = 0;
//		t.tic();
		std::vector< std::vector< ParameterConstraint > > non_empty_constraints;
		for( int i=0; i<constraints.size(); i++ )
			if( constraints[i].size() )
				non_empty_constraints.push_back( constraints[i] );
		std::tie(unary_,pairwise_) = objective.optimize( non_empty_constraints, &o_val );
//		t.toc("QP");
		if( verbose > 1 )
			printf(" Optimized to %f\n", o_val );
	}
	float e2=0;
#pragma omp parallel for num_threads(N_THREAD)
	for( int i=0; i<N; i++ ) {
		VectorXf X = map( f[i] );
		const float ls = loss.evaluate( X, l[i].cast<float>() );
#pragma omp atomic
		e2 += ls;
	}
	if( verbose > 0 )
		printf("The algorithm converged after %d iterations. Duality GAP: %f - %f\n", niter, e1/N, e2/N );
	if( verbose > 1 ) {
		std::cout<<"  unary    = "<<unary_.transpose()<<std::endl;
		std::cout<<"  pairwise = "<<pairwise_.transpose()<<std::endl;
		printf("\n");
	}
}

void BinaryCRF::load( std::istream & is ) {
	loadMatrixX( is, unary_ );
	loadMatrixX( is, pairwise_ );
}
void BinaryCRF::save( std::ostream & os ) const {
	saveMatrixX( os, unary_ );
	saveMatrixX( os, pairwise_ );
}
void BinaryCRF::setUnary(const VectorXf& unary) {
    unary_ = unary;
}
void BinaryCRF::setPairwise(const VectorXf& pairwise) {
    pairwise_ = pairwise;
}
const VectorXf & BinaryCRF::unary() const {
    return unary_;
}
const VectorXf & BinaryCRF::pairwise() const {
    return pairwise_;
}

