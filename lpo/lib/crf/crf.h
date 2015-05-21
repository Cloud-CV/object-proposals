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
#include "util/graph.h"
#include <memory>

class BinaryCRFFeatures {
public:
	virtual const RMatrixXf & unary() const = 0;
	virtual const RMatrixXf & pairwise() const = 0;
	virtual const Edges & graph() const = 0;
	
	virtual ~BinaryCRFFeatures();
};
// Binary loss function of the type f(true pos, false pos, false neg, true neg)
// If the function is linear, then we can precompute if from the number of positives NP=(TP+FN) and the number of negatives NN = (FN+FP)
class TrainingLoss {
public:
	virtual ~TrainingLoss();
	virtual bool isLinear() const = 0;
	virtual float evaluate( float TP, float FP, float FN, float TN ) const = 0;
	virtual float evaluate( const VectorXf & X, const VectorXf & gt ) const;
};
struct ParameterConstraint {
	// A constraint such that: du*unary_ + dp*pairwise_ + loss <= 0
	VectorXf du, dp;
	float loss;
	ParameterConstraint();
	float slack( const VectorXf & unary, const VectorXf & pairwise ) const;
	ParameterConstraint & operator+=( const ParameterConstraint & o );
	ParameterConstraint & operator*=( const float & o );
};
class MaxMarginObjective {
protected:
	friend class BinaryCRF;
public:
	virtual ~MaxMarginObjective();
	virtual std::tuple<VectorXf,VectorXf> optimize( const std::vector< std::vector<ParameterConstraint> > & constraints, float * objective_value=NULL ) const = 0;
};

class BinaryCRF {
protected:
	VectorXf unary_, pairwise_;
	ParameterConstraint generateConstraint( const BinaryCRFFeatures & f, const VectorXs & l, const TrainingLoss & loss ) const;
public:
	BinaryCRF();
	bool operator==(const BinaryCRF & o) const;
	VectorXf map( const std::shared_ptr<BinaryCRFFeatures> & f, float * e=0 ) const;
	RMatrixXf diverseMBest( const std::shared_ptr<BinaryCRFFeatures> & f, int M, const TrainingLoss & loss ) const;
	float e( const VectorXf & s, const std::shared_ptr<BinaryCRFFeatures> & f ) const;
	
	// Training functions
	void train( const std::shared_ptr<BinaryCRFFeatures> & f, const VectorXs & l, const TrainingLoss & loss );
	void train( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l, const TrainingLoss & loss );
	void train( const std::shared_ptr<BinaryCRFFeatures> & f, const VectorXs & l );
	void train( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l );
	void train1Slack( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l, const TrainingLoss & loss );
	void trainNSlack( const std::vector< std::shared_ptr<BinaryCRFFeatures> > & f, const std::vector<VectorXs> & l, const TrainingLoss & loss );
	bool isTrained() const;
	
	// Static CRF functions
	static VectorXf inference( const VectorXf & u, const Edges & g, const VectorXf & w, float * e=0 );
	static VectorXf inferenceWithLoss( const VectorXf & u, const Edges & g, const VectorXf & w, const VectorXs & l, const TrainingLoss & loss );
	static VectorXf inferenceWithIOU( const VectorXf & u, const Edges & g, const VectorXf & w, const VectorXs & l, float k );
	static float energy( const VectorXf & l, const VectorXf & u, const Edges & g, const VectorXf & w );
	
	// Save and load
	void load( std::istream & is );
	void save( std::ostream & os ) const;
	
	// Get and set parameters
	void setUnary( const VectorXf & unary );
	void setPairwise( const VectorXf & pairwise );
	const VectorXf & unary() const;
	const VectorXf & pairwise() const;
};
