#include "mex.h"
#include <math.h>
#include <stdio.h>

#define NEWA(type,n) (type*)mxMalloc(sizeof(type)*(n))
#define FREE(p) mxFree(p)
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

void bescores(double *winscores, double *windows,int nwin, int nsubbox, double *oribinintim, int rows,int cols,double *BoxWeights,double *BoxIndices)
{

  int i,j,k,l;
  int *Xstart=NEWA(int,2*nsubbox+1);
  int *Ystart=NEWA(int,2*nsubbox+1);
  double *winhists=NEWA(double,4*nsubbox*nsubbox);
  double wi,hi,cxi,cyi,xa,xb,ya,yb;
  double twonsubbox;
  int a,b,npix,sift;

  twonsubbox=2.0*nsubbox;
  a=2*nsubbox;
  b=a+1;
  npix=rows*cols;

  for (i=0;i<nwin;i++){
    *(winscores+i)=0.0;
    xa=*(windows+i);
    ya=*(windows+nwin+i);
    xb=*(windows+nwin+nwin+i);
    yb=*(windows+nwin+nwin+nwin+i);
    wi=xb-xa+1.0;
    hi=yb-ya+1.0;
    cxi=0.5*(xa+xb);
    cyi=0.5*(ya+yb);
    
    if (wi<twonsubbox | hi<twonsubbox){
      continue;
    }
    for (j=0;j<b;j++){
      *(Xstart+j)=(int)MAX(1.0,ceil((((double)j)/((double)a)-0.5)*wi+cxi)-1.0);
      *(Ystart+j)=(int)MAX(1.0,ceil((((double)j)/((double)a)-0.5)*hi+cyi)-1.0);
    }
    for (j=0;j<a;j++){
      for (k=0;k<a;k++){
	l=((int)*(BoxIndices+k*a+j));
	sift=(l-1)*npix;
	*(winhists+k*a+j)=*(oribinintim+sift+(*(Xstart+k+1)-1)*rows+(*(Ystart+j+1))-1)+*(oribinintim+sift+(*(Xstart+k)-1)*rows+(*(Ystart+j))-1)-*(oribinintim+sift+(*(Xstart+k)-1)*rows+(*(Ystart+j+1))-1)-*(oribinintim+sift+(*(Xstart+k+1)-1)*rows+(*(Ystart+j))-1);
	*(winscores+i)=*(winscores+i)+*(BoxWeights+k*a+j)*(*(winhists+k*a+j));
      }
    }
  }

  FREE(Xstart);
  FREE(Ystart);
  FREE(winhists);
}

 
/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
  double *winscores, *windows, *oribinintim, *BoxWeights,*BoxIndices;
  int nbin,nsubbox,nwin,rows,cols;
  
  nbin=(int)mxGetScalar(prhs[2]);
  nsubbox=(int)mxGetScalar(prhs[3]);
  windows = mxGetPr(prhs[0]);
  oribinintim = mxGetPr(prhs[1]);
  BoxWeights = mxGetPr(prhs[4]);
  BoxIndices = mxGetPr(prhs[5]);
  nwin=(int)mxGetM(prhs[0]);
  rows=(int)mxGetM(prhs[1]);
  cols=(int)mxGetN(prhs[1]);
  cols=cols/nbin;
  plhs[0] = mxCreateDoubleMatrix(nwin,1, mxREAL);
  winscores = mxGetPr(plhs[0]);

  bescores(winscores, windows, nwin, nsubbox, oribinintim,rows,cols,BoxWeights, BoxIndices);
  
}
