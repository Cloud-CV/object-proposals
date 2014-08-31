/* intHist = computeIntegralHistogramMex(quantMatrix,height,width,prodQuant);  computes the integral image of an image with  */


#include <math.h>
#include "mex.h"

void mexFunction( int nlhs, mxArray *plhs[],
          int nrhs, const mxArray *prhs[] )
     
{
    double    *quantMatrix, *intHist;
    int    height,width,prodQuant;
    
    /* Check for proper number of arguments */
    
    if (nrhs != 4) {
     mexErrMsgTxt("4 input argument required.");
    } 
    else if (nlhs > 1) {
     mexErrMsgTxt("Too many output arguments.");
    }

    if ( !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[1]) != 2 )
		mexErrMsgTxt("input 1 (quantMatrix) must be a real double matrix");
   
    quantMatrix = mxGetPr(prhs[0]);
    height = mxGetScalar(prhs[1]);
    width = mxGetScalar(prhs[2]);
    prodQuant = mxGetScalar(prhs[3]);
    
    /* Create a matrix for the return argument */
    
    plhs[0] = mxCreateDoubleMatrix(prodQuant,(height+1)*(width+1),mxREAL);/* size of intHist*/
    
    intHist = mxGetPr(plhs[0]);

    int i,j,k,x1;
 
    for(i = 1;i <= height;i++)
       for(j = 1;j <= width;j++)
        {
         x1 = floor(quantMatrix[(j-1)*height+(i-1)]);
         
         intHist[prodQuant*(j*(height+1)+i)+x1-1]=1; /* corresponding bin has value=1 at location (i,j) */

         for(k = 0;k < prodQuant;k++) 
            intHist[prodQuant*(j*(height+1)+i)+k] += intHist[prodQuant*(j*(height+1)+i-1)+k] + intHist[prodQuant*((j-1)*(height+1)+i)+k] - intHist[prodQuant*((j-1)*(height+1)+i-1)+k];
        }  
     
    return;    
}
