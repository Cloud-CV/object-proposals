/*contrast = computeScoreContrast(integralHistogram,height,width,xmin,ymin,xmax,ymax,thetaCC,prodQuant,numberWindows); */

#include <math.h>
#include "mex.h"

#if !defined(MAX)
#define    MAX(A, B)    ((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define    MIN(A, B)    ((A) < (B) ? (A) : (B))
#endif



void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
     
{
    const double *integralHistogram;
    double       *contrast,*inside,*outside,*inside1,*outside1,*aux;
    double       *xmin, *ymin, *xmax, *ymax;
    int          prodQuant, numberWindows, w;
    int          height, width, thetaCC;
    double       sum_inside=0, sum_outside=0;
    double       factor = 0.0;
    int          i,j,k;
    int          xminSurr,xmaxSurr,yminSurr,ymaxSurr,objWidth,objHeight;
    int          minmin,minmax,maxmin,maxmax;
    double       offsetWidth=0.0, offsetHeight=0.0,x1,x2,y1,y2; 

    /* Check for proper number of arguments */    
    if (nrhs != 10) {
    mexErrMsgTxt("10 input argument required.");
    } else if (nlhs > 1) {
    mexErrMsgTxt("Too many output arguments.");
    }
    
    integralHistogram = mxGetPr(prhs[0]);
    
    height = mxGetScalar(prhs[1]);
    width = mxGetScalar(prhs[2]);   
    xmin = mxGetPr(prhs[3]);
    ymin = mxGetPr(prhs[4]);    
    xmax = mxGetPr(prhs[5]);
    ymax = mxGetPr(prhs[6]);
    thetaCC = mxGetScalar(prhs[7]); 
    prodQuant = mxGetScalar(prhs[8]);
    numberWindows = mxGetScalar(prhs[9]);

    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 2 || mxGetN(prhs[0]) != (height+1)*(width+1))
		mexErrMsgTxt("input 1 (integralHistogram) must be a real double matrix");
    
    plhs[0] = mxCreateDoubleMatrix(numberWindows,1,mxREAL);
    
    contrast = mxGetPr(plhs[0]);
    
    inside=mxGetPr(mxCreateDoubleMatrix(prodQuant,1,mxREAL));
    outside=mxGetPr(mxCreateDoubleMatrix(prodQuant,1,mxREAL)); 

    inside1=mxGetPr(mxCreateDoubleMatrix(prodQuant,1,mxREAL));
    outside1=mxGetPr(mxCreateDoubleMatrix(prodQuant,1,mxREAL)); 
      
    for(w=0;w<numberWindows;w++)
    {
        
    	objWidth=xmax[w]-xmin[w]+1;
     	objHeight=ymax[w]-ymin[w]+1;
        sum_inside = 0;
        
    	if((objWidth<=0)||(objHeight<=0))
      		mxErrMsgTxt("error xmax - xmin <=0 or ymax - ymin<=0");  
              
        maxmax = (int)(prodQuant*(xmax[w]*(height+1)+ymax[w]));
        minmin = (int)(prodQuant*((xmin[w]-1)*(height+1)+ymin[w]-1));
        maxmin = (int)(prodQuant*(xmax[w]*(height+1)+ymin[w]-1));
        minmax = (int)(prodQuant*((xmin[w]-1)*(height+1)+ymax[w]));
        
        for(k=0;k<prodQuant;k++) 
        {              
            inside[k] = integralHistogram[maxmax+k] + integralHistogram[minmin+k] -integralHistogram[maxmin+k] - integralHistogram[minmax+k];          
            sum_inside+=inside[k];
        }
        
        
        
    	for(k=0;k<prodQuant;k++)
    	{
    	if(sum_inside)
      		inside1[k]=inside[k]/sum_inside;
    	}  
      
       offsetWidth=(double)objWidth*thetaCC/200;
       offsetHeight=(double)objHeight*thetaCC/200;

       xminSurr=round(MAX(xmin[w]-offsetWidth,1));
       xmaxSurr=round(MIN(xmax[w]+offsetWidth,width));
       yminSurr=round(MAX(ymin[w]-offsetHeight,1));
       ymaxSurr=round(MIN(ymax[w]+offsetHeight,height));
       
       maxmax = (int)(prodQuant*(xmaxSurr*(height+1)+ymaxSurr));
       minmin = (int)(prodQuant*((xminSurr-1)*(height+1)+yminSurr-1));
       maxmin = (int)(prodQuant*(xmaxSurr*(height+1)+yminSurr-1));
       minmax = (int)(prodQuant*((xminSurr-1)*(height+1)+ymaxSurr));
        
       sum_outside=0;
       for(k=0;k<prodQuant;k++)
       {          
          outside[k] = integralHistogram[maxmax + k] + integralHistogram[minmin+k] - integralHistogram[maxmin+k] - integralHistogram[minmax+k] - inside[k];
          sum_outside += outside[k];
       }
        
       
       for(k=0;k<prodQuant;k++)
       {
          if(sum_outside)
          {
             outside1[k]=outside[k]/sum_outside;
             if(outside1[k]+inside1[k])
               contrast[w]+=(inside1[k] - outside1[k])*(inside1[k] - outside1[k])/(inside1[k] + outside1[k]);
          }
          else               
              contrast[w]=0;
       }

    }
    
    return;
    
}
