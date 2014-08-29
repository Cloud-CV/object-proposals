/*proposals=RP_mex(rgbI, params);*/

#include <math.h>
#include "mex.h"
#include "rp.h"
#include "mex_helper.h"



void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{


  if (nrhs != 2) {
    mexErrMsgTxt("2 input argument required: rgbI, params");
  } 
  else if (nlhs != 1) {
    mexErrMsgTxt("There must be just one output.");
  }

  if ( !mxIsUint8(prhs[0]) )
    mexErrMsgTxt("input 1 (rgbI) must be UINT8");

  if ( !mxIsStruct(prhs[1]) )
    mexErrMsgTxt("input 2 (params) must be a STRUCT");

  if(mxGetNumberOfDimensions(prhs[0])!=3)
    mexErrMsgTxt("input 1 (rgbI) should have 3 dimensions.");

  const mwSize * const imgSize= mxGetDimensions(prhs[0]);
  const uint imgH = imgSize[0]; 
  const uint imgW = imgSize[1];
  const uint nChannels = imgSize[2];

  if(nChannels<3)
    mexErrMsgTxt("input 1 (rgbI) should have should have 3 channels.");

  const Image rgbI((uchar *)mxGetData(prhs[0]), std::vector<uint>(imgSize,imgSize+3),RGB);
  const Params params=ParamsFromMexArray(prhs[1]);

  const uint nProposals = params.nProposals();
  assert(nProposals>0);

  plhs[0]=mxCreateDoubleMatrix( nProposals, 4, mxREAL);

  double * bbProposals=mxGetPr(plhs[0]);

  std::vector<BBox> bbProposalsVector = RP( rgbI, params);
  assert(bbProposalsVector.size()==nProposals);

  uint k=0;
  for( k=0; k<bbProposalsVector.size();k++){
    bbProposals[k]=bbProposalsVector.at(k).jMin+1;
    bbProposals[nProposals+k]=bbProposalsVector.at(k).iMin+1;
    bbProposals[nProposals*2+k]=bbProposalsVector.at(k).jMax+1;
    bbProposals[nProposals*3+k]=bbProposalsVector.at(k).iMax+1;
  }
}

