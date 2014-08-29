#include "mex.h"
#include <math.h>
#include <stdio.h>

#define NEWA(type,n) (type*)mxMalloc(sizeof(type)*(n))
#define FREE(p) mxFree(p)
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

void selectwindows(double *ids,double *xa, double *ya, double *xb, double *yb, int n, int nw, double overlaplimit)
{
  int i, k,checksum, countera, counterb, counterc;
  int *indicator=NEWA(int,nw);
  double overlap=0.0,x,y,u,v,interarea=0.0,unionarea=0.0;
  countera=1;
  counterb=2;
  checksum=0;
  
  for (i=0;i<nw;i++){
    *(indicator+i)=0;
  }
  for (i=0;i<n;i++){
    *(ids+i)=0;
  }
  *ids=1.0;
  *indicator=1;
  
  while (countera<n){
    checksum=0;
    *(indicator+(counterb-1))=0;
    for (i=0;i<countera;i++){
      k=counterb-1;
      x=MAX(*(xa+(((int)*(ids+i))-1)),*(xa+k));
      y=MAX(*(ya+(((int)*(ids+i))-1)),*(ya+k));
      u=MIN(*(xb+(((int)*(ids+i))-1)),*(xb+k));
      v=MIN(*(yb+(((int)*(ids+i))-1)),*(yb+k));
      interarea=MAX(0,u-x)*MAX(0,v-y);
      unionarea=(*(xb+(((int)*(ids+i))-1))-*(xa+(((int)*(ids+i))-1)))*(*(yb+(((int)*(ids+i))-1))-*(ya+(((int)*(ids+i))-1)))+(*(xb+k)-*(xa+k))*(*(yb+k)-*(ya+k))-interarea;
      overlap=interarea/unionarea;
      if (overlap>overlaplimit){
	checksum=1;
      }
    }
    if (checksum==0){
      countera=countera+1;
      *(ids+(countera-1))=counterb;
      *(indicator+(counterb-1))=1;
    }
    counterb=counterb+1;
    if (counterb>nw){
      counterc=1;
      while ((counterc<nw) & (countera<n)){
	if (*(indicator+(counterc-1))==0){
	  countera=countera+1;
	  *(ids+(countera-1))=counterc;
	} 
	counterc=counterc+1;
      }
    }

  }
  FREE(indicator);
}

 
/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
  double overlaplimit, *xa,*ya,*xb,*yb, *ids;
  int n,nw;
  
  n=(int)mxGetScalar(prhs[4]);
  overlaplimit=mxGetScalar(prhs[5]);
  xa = mxGetPr(prhs[0]);
  ya = mxGetPr(prhs[1]);
  xb = mxGetPr(prhs[2]);
  yb = mxGetPr(prhs[3]);
  nw=(int)mxGetM(prhs[0]);
  plhs[0] = mxCreateDoubleMatrix(n,1, mxREAL);
  ids = mxGetPr(plhs[0]);

  selectwindows(ids,xa,ya,xb,yb,n,nw,overlaplimit);
  
}
