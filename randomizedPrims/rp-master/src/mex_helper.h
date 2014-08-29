#ifndef MEX_HELPER_H
#define MEX_HELPER_H

#include "params.h"


std::string MxArrayToString(const mxArray * const array_ptr){
    assert(mxIsChar(array_ptr));
    const uint len=mxGetN(array_ptr)+1;
    char * s=new char[len];
    mxGetString(array_ptr,s,len);
    return std::string(s,len);
}

Params ParamsFromMexArray(const mxArray * const s){

  Params p;

  mxArray * array_ptr=0;
  char * str=0;
  uint len=0;
  int substructure_field_num=0;

  //N proposals
  array_ptr=mxGetField(s,0,"nProposals");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    p.setNProposals((uint)mxGetScalar(array_ptr));
    assert(p.nProposals()>0);
  }else{
    assert(0);
  }

  //Colorspace
  array_ptr=mxGetField(s,0,"colorspace");
  if(array_ptr){
    std::string cs=MxArrayToString(array_ptr);
    if(!strcmp(cs.c_str(),"RGB")){
      p.setColorspace(RGB);
    }else if(!strcmp(cs.c_str(),"rg")){
      p.setColorspace(rg);
    }else if(!strcmp(cs.c_str(),"LAB")){
      p.setColorspace(LAB);
    }else if(!strcmp(cs.c_str(),"opponent")){
      p.setColorspace(Opponent);
    }else if(!strcmp(cs.c_str(),"HSV")){
      p.setColorspace(HSV);
    }else{
      mexErrMsgTxt("Colorspace unknown.");
    }

  }else{
    mexErrMsgTxt("Missing colorspace parameter.");
  }

  //Similarity features

  substructure_field_num = mxGetFieldNumber(s, "simWeights");
  mxArray * simWeights = mxGetFieldByNumber(s, 0, substructure_field_num);

  Params::FWeights fWeights;
  array_ptr=mxGetField(simWeights,0,"wBias");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    fWeights.wBias_=mxGetScalar(array_ptr);
  }else{
    fWeights.wBias_=0.0;
  }

  array_ptr=mxGetField(simWeights,0,"wCommonBorder");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    fWeights.wCommonBorder_=mxGetScalar(array_ptr);
  }else{
    fWeights.wCommonBorder_=0.0;
  }

  array_ptr=mxGetField(simWeights,0,"wLABColorHist");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    fWeights.wLABColorHist_=mxGetScalar(array_ptr);
  }else{
    fWeights.wLABColorHist_=0.0;
  }

  array_ptr=mxGetField(simWeights,0,"wSizePer");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    fWeights.wSizePer_=mxGetScalar(array_ptr);
  }else{
    fWeights.wSizePer_=0.0;
  }

  p.setFWeights(fWeights);

  //Superpixel segmentation
  substructure_field_num = mxGetFieldNumber(s, "superpixels");
  mxArray * superpixels = mxGetFieldByNumber(s, 0, substructure_field_num);

  Params::SpParams spParams;
  
  array_ptr=mxGetField(superpixels,0,"sigma");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    spParams.sigma_=mxGetScalar(array_ptr);
  }else{
    assert(0);
  }

  array_ptr=mxGetField(superpixels,0,"c");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    spParams.c_=mxGetScalar(array_ptr);
  }else{
    assert(0);
  }

  array_ptr=mxGetField(superpixels,0,"min_size");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    spParams.min_size_=mxGetScalar(array_ptr);
  }else{
    assert(0);
  }

  p.setSpParams(spParams);

  //Alpha distribution (should be 16 bits LUT):
  array_ptr=mxGetField(s,0,"alpha");
  double * a=NULL;
  if(array_ptr){
    assert(mxIsDouble(array_ptr));
    assert(mxGetM(array_ptr)==65536);
    assert(mxGetN(array_ptr)==1);
    a=(double *)mxGetData(array_ptr);

    p.setAlpha(std::vector<double>(a, a+65536));

  }else{
    assert(0);
  }

  //Seed for random number generator:
  array_ptr=mxGetField(s,0,"rSeedForRun");
  if(array_ptr){
    assert(mxIsNumeric(array_ptr));
    p.setRSeedForRun((uint)mxGetScalar(array_ptr));
    assert(p.nProposals()>0);
  }else{
    p.setRSeedForRun(-1);
  }

  array_ptr=mxGetField(s,0,"verbose");
  if(array_ptr){
    assert(mxIsLogical(array_ptr));
    p.setVerbose((bool) mxGetScalar(array_ptr));
  }else{
    assert(0);
  }


  if(p.verbose()){
    mexPrintf("====Loaded Params===================================\n");


  mexPrintf("====Loaded Params===================================\n");

  mexPrintf("- nProposals: %d\n",p.nProposals());
  mexPrintf("- colorspace: %d\n",p.colorspace());
  mexPrintf("  (RGB, rg, LAB, Opponent, HSV)\n");
  mexPrintf("- Superpixels:\n");
  mexPrintf("  - sigma: %f\n",p.spParams().sigma_);
  mexPrintf("  - c: %f\n",p.spParams().c_);
  mexPrintf("  - min_size: %f\n",p.spParams().min_size_);
  mexPrintf("- Similarity weights:\n");
  mexPrintf("  - Bias: %f\n",p.fWeights().wBias_);
  mexPrintf("  - Common Border: %f\n",p.fWeights().wCommonBorder_);
  mexPrintf("  - LAB Color Hist: %f\n",p.fWeights().wLABColorHist_);
  mexPrintf("  - Size Per: %f\n",p.fWeights().wSizePer_);
  mexPrintf("- Random seed: %d\n", p.rSeedForRun());
  mexPrintf("====Loaded Params===================================\n");

  }

  return p;
}


#endif
