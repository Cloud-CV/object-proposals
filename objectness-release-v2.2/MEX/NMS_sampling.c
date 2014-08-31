#include <math.h>
#include "mex.h"
#include "matrix.h"

#if !defined(MAX)
#define    MAX(A, B)    ((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define    MIN(A, B)    ((A) < (B) ? (A) : (B))
#endif



void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
     
{       
    double       *xmin, *ymin, *xmax, *ymax, *area, overlap, *visited, xx1,yy1,xx2,yy2,width,height,ov,*ndx;            
    long int          w, j, numberWindows,all,ndxNotVisited;   
    
    /* Check for proper number of arguments */    
    if (nrhs != 7) {
    mexErrMsgTxt("7 input argument required.");
    } else if (nlhs > 2) {
    mexErrMsgTxt("Too many output arguments.");
    }        
    
    area = mxGetPr(prhs[0]);
    overlap = mxGetScalar(prhs[1]);   
    xmin = mxGetPr(prhs[2]);
    ymin = mxGetPr(prhs[3]);    
    xmax = mxGetPr(prhs[4]);
    ymax = mxGetPr(prhs[5]);
    numberWindows = mxGetScalar(prhs[6]);
    plhs[0] = mxCreateDoubleMatrix(numberWindows,1,mxREAL);    
    ndx = mxGetPr(plhs[0]); 
    for(w=0;w<numberWindows;w++)
        ndx[w] = -1;
        
    all = 100000;     
    visited = mxGetPr(mxCreateDoubleMatrix(all,1,mxREAL));                 
    
    plhs[1] = mxCreateDoubleMatrix(all,1,mxREAL);    
    visited = mxGetPr(plhs[1]); 
    
    
    for(j=0;j<all;j++)
        visited[j]=0;
    
    ndxNotVisited = 0;    
    for(w=0;w<numberWindows;w++){      
        ndx[w] = ndxNotVisited;
        visited[ndxNotVisited] = 1;        
        
        for(j = ndxNotVisited+1; j<all;j++){
            xx1 = MAX(xmin[ndxNotVisited], xmin[j]);
            yy1 = MAX(ymin[ndxNotVisited], ymin[j]);
            xx2 = MIN(xmax[ndxNotVisited], xmax[j]);
            yy2 = MIN(ymax[ndxNotVisited], ymax[j]);
            width = xx2 - xx1 + 1;
            height = yy2 - yy1 + 1;
            if ((width >0) && (height > 0)){
                ov = (width * height)/(area[ndxNotVisited] + area[j] - width * height);
                if (ov > 0.5)
                    visited[j] = 1;                
            }    
        }
            
        while((ndxNotVisited < all) && (visited[ndxNotVisited] > 0))        
            ndxNotVisited = ndxNotVisited + 1;
                        
        if (ndxNotVisited == all)        
            break;                        
    }
    return;
}