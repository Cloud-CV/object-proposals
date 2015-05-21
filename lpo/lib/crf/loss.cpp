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
#include "loss.h"

HammingLoss::HammingLoss( float w_pos, float w_neg ):w_pos_(w_pos),w_neg_(w_neg){
}
bool HammingLoss::isLinear() const {
	return true;
}
float HammingLoss::evaluate( float TP, float FP, float FN, float TN ) const {
	return (w_pos_ * FN + w_neg_ * FP) / (TP+FN+FP+TN);
}

AverageHammingLoss::AverageHammingLoss( float w ):w_(w) {
}
bool AverageHammingLoss::isLinear() const {
	return true;
}
float AverageHammingLoss::evaluate( float TP, float FP, float FN, float TN ) const {
	return w_*0.5*( FN/(TP+FN) + FP/(FP+TN) );
}

LinearJaccardLoss::LinearJaccardLoss( float w ):w_(w) {
}
bool LinearJaccardLoss::isLinear() const {
	return true;
}
float LinearJaccardLoss::evaluate( float TP, float FP, float FN, float TN ) const {
	return w_*(FN+0.5*FP)/(TP+FN);
}

ApproximateJaccardLoss::ApproximateJaccardLoss( float w, float p ):w_(w),p_(p) {
}
bool ApproximateJaccardLoss::isLinear() const {
	return true;
}
float ApproximateJaccardLoss::evaluate( float TP, float FP, float FN, float TN ) const {
	float pos_norm = pow(TP+FN,p_), neg_norm = pow(FP+TN,p_);
	return w_*(FN/pos_norm + FP/neg_norm) / ((TP+FN)/pos_norm + (FP+TN)/neg_norm);
}

JaccardLoss::JaccardLoss(float w):w_(w) {
}
bool JaccardLoss::isLinear() const {
	return false;
}
float JaccardLoss::evaluate( float TP, float FP, float FN, float TN ) const {
	return w_*(FP+FN)/(TP+FN+FP);
}
float JaccardLoss::w() const {
	return w_;
}
