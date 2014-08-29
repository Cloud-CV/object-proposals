#include "mex.h"
#include <math.h>
#include <stdio.h>

#define NEWA(type,n) (type*)mxMalloc(sizeof(type)*(n))
#define FREE(p) mxFree(p)
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

void wsscores(double *winscores, double *windows,int nwin, int nsubbox, double *oribinintim, int nbin,int rows,int cols,double *BoxWeights)
{

  int i,j,k,l;
  int *Xstart=NEWA(int,2*nsubbox+1);
  int *Ystart=NEWA(int,2*nsubbox+1);
  double *winhists=NEWA(double,4*nsubbox*nsubbox*nbin);
  double wi,hi,cxi,cyi,xa,xb,ya,yb;
  double twonsubbox,intersection;
  int a,b,npix,sift,sifth,aa;

  twonsubbox=2.0*nsubbox;
  a=2*nsubbox;
  aa=a*a;
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
	for (l=0;l<nbin;l++){
	  sift=(l)*npix;
	  sifth=l*aa;
	  *(winhists+k*a+j+sifth)=*(oribinintim+sift+(*(Xstart+k+1)-1)*rows+(*(Ystart+j+1))-1)+*(oribinintim+sift+(*(Xstart+k)-1)*rows+(*(Ystart+j))-1)-*(oribinintim+sift+(*(Xstart+k)-1)*rows+(*(Ystart+j+1))-1)-*(oribinintim+sift+(*(Xstart+k+1)-1)*rows+(*(Ystart+j))-1);
	}
      }
    }
    
    sift=0.0;
    intersection=0.0;
    for (j=0;j<nsubbox;j++){
      for (k=0;k<nsubbox;k++){
	for (l=0;l<nbin;l++){
	  sifth=l*aa;
	  switch (l){
	  case 0:
	    sift=0;
	    break;
	  case 1:
	    sift=3*aa;
	    break;
	  case 2:
	    sift=2*aa;
	    break;
	  case 3:
	    sift=aa;
	    break;
	  default:
	    printf("nbin should be four \n");
	    break;
	  }
	  intersection=intersection+*(BoxWeights+k*a+j)*MIN((*(winhists+k*a+j+sifth)),(*(winhists+(a-1-k)*a+j+sift)));
	}
      }
    }
    *(winscores+i)=*(winscores+i)+intersection;

    sift=0.0;
    intersection=0.0;
    for (j=0;j<nsubbox;j++){
      for (k=0;k<nsubbox;k++){
	for (l=0;l<nbin;l++){
	  sifth=l*aa;
	  switch (l){
	  case 0:
	    sift=0;
	    break;
	  case 1:
	    sift=3*aa;
	    break;
	  case 2:
	    sift=2*aa;
	    break;
	  case 3:
	    sift=aa;
	    break;
	  default:
	    printf("nbin should be four \n");
	    break;
	  }
	  intersection=intersection+*(BoxWeights+k*a+j)*MIN((*(winhists+k*a+j+sifth)),(*(winhists+k*a+(a-1-j)+sift)));
	}
      }
    }
    *(winscores+i)=*(winscores+i)+intersection;

    sift=0.0;
    intersection=0.0;
    for (j=nsubbox;j<a;j++){
      for (k=0;k<nsubbox;k++){
	for (l=0;l<nbin;l++){
	  sifth=l*aa;
	  switch (l){
	  case 0:
	    sift=0;
	    break;
	  case 1:
	    sift=3*aa;
	    break;
	  case 2:
	    sift=2*aa;
	    break;
	  case 3:
	    sift=aa;
	    break;
	  default:
	    printf("nbin should be four \n");
	    break;
	  }
	  intersection=intersection+*(BoxWeights+k*a+j)*MIN((*(winhists+k*a+j+sifth)),(*(winhists+(a-1-k)*a+j+sift)));
	}
      }
    }
    *(winscores+i)=*(winscores+i)+intersection;
 
    sift=0.0;
    intersection=0.0;
    for (j=0;j<nsubbox;j++){
      for (k=nsubbox;k<a;k++){
	for (l=0;l<nbin;l++){
	  sifth=l*aa;
	  switch (l){
	  case 0:
	    sift=0;
	    break;
	  case 1:
	    sift=3*aa;
	    break;
	  case 2:
	    sift=2*aa;
	    break;
	  case 3:
	    sift=aa;
	    break;
	  default:
	    printf("nbin should be four \n");
	    break;
	  }
	  intersection=intersection+*(BoxWeights+k*a+j)*MIN((*(winhists+k*a+j+sifth)),(*(winhists+k*a+(a-1-j)+sift)));
	}
      }
    }
    *(winscores+i)=*(winscores+i)+intersection;

  }

  FREE(Xstart);
  FREE(Ystart);
  FREE(winhists);
}

 
/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
  double *winscores, *windows, *oribinintim, *BoxWeights;
  int nbin,nsubbox,nwin,rows,cols;
  
  nbin=(int)mxGetScalar(prhs[2]);
  nsubbox=(int)mxGetScalar(prhs[3]);
  windows = mxGetPr(prhs[0]);
  oribinintim = mxGetPr(prhs[1]);
  BoxWeights = mxGetPr(prhs[4]);
  nwin=(int)mxGetM(prhs[0]);
  rows=(int)mxGetM(prhs[1]);
  cols=(int)mxGetN(prhs[1]);
  cols=cols/nbin;
  plhs[0] = mxCreateDoubleMatrix(nwin,1, mxREAL);
  winscores = mxGetPr(plhs[0]);

  wsscores(winscores, windows, nwin, nsubbox, oribinintim,nbin,rows,cols,BoxWeights);
  
}
