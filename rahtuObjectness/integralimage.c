#include "mex.h"
#include <math.h>
#include <stdio.h>

#define NEWA(type,n) (type*)mxMalloc(sizeof(type)*(n))
#define FREE(p) mxFree(p)
#define PI 3.141592653589793
#define TH 0.8


void integralimage(double *iim,double *im,int m,int n)
{
  int i,j, ia,ib,ic,id;

  for (i=1;i<=m;i++){
    for (j=1;j<=n;j++){
      id=(j-1)*m+i-1;
      *(iim+id)=*(im+id);
      if (i>1){
	ib=(j-1)*m+i-2;
	*(iim+id)=*(iim+id)+*(iim+ib);
      }
      if (j>1){
	ic=(j-2)*m+i-1;
	*(iim+id)=*(iim+id)+*(iim+ic);
      }
      if (i>1 && j>1){
	ia=(j-2)*m+i-2;
	*(iim+id)=*(iim+id)-*(iim+ia);
      }	     
    }
  }

}

/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
  double *iim,*im;
  int m,n;
 
  im=mxGetPr(prhs[0]);
  m=(int)mxGetM(prhs[0]);
  n=(int)mxGetN(prhs[0]);

  plhs[0] = mxCreateDoubleMatrix(m,n, mxREAL);
  iim=mxGetPr(plhs[0]);
  integralimage(iim,im,m,n);
}
