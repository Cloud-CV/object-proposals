/* scoreScale = slidingWindowComputeScore(double(saliencyMAP),scale,min_width,min_height,threshold,salmapIntegralImage,thrmapIntegralImage);*/

#include <math.h>
#include "mex.h"

void mexFunction( int nlhs, mxArray *plhs[],
          int nrhs, const mxArray *prhs[] )
     
{
    double *saliencyMAP, *scoreScale, *salmapIntegralImage, *thrmapIntegralImage, threshold, athr, aval;
    int    scale, min_width, min_height, area , image_area;
    
    int xmin,ymin,xmax,ymax,i,j,k;    
 
    /* Check for proper number of arguments */
    
    if (nrhs != 7) {
     mexErrMsgTxt("7 input argument required.");
    } 
    else if (nlhs > 1) {
     mexErrMsgTxt("Too many output arguments.");
    }

    if ( !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 2 )
		mexErrMsgTxt("input 1 (h) must be a real double matrix 64 x 64");
    


    saliencyMAP = mxGetPr(prhs[0]);/*saliencyMAP */
   
    scale = mxGetScalar(prhs[1]);/* 64-48-32-24-16 */
    min_width = mxGetScalar(prhs[2]);
    min_height = mxGetScalar(prhs[3]);
    threshold = mxGetScalar(prhs[4]);
    salmapIntegralImage = mxGetPr(prhs[5]);/*salmapIntegralImage */
    thrmapIntegralImage = mxGetPr(prhs[6]);/*thrmapIntegralImage */
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(scale*scale,scale*scale,mxREAL);
    scoreScale = mxGetPr(plhs[0]);

    image_area = scale * scale;
    
    for(xmin = 1;xmin <= scale - min_width + 1;xmin += 1)
       for(ymin = 1;ymin <= scale - min_height + 1;ymin += 1)
          for(xmax = xmin + min_width - 1;xmax <= scale;xmax += 1)
             for(ymax = ymin + min_height - 1;ymax <= scale;ymax += 1)
               {        
                 area = (xmax-xmin+1)*(ymax-ymin+1);
                 aval = salmapIntegralImage[(scale+1)*(xmax-1 +1)+(ymax-1+1)] + salmapIntegralImage[(scale+1)*(xmin-1)+(ymin-1)] - salmapIntegralImage[(scale+1)*(xmax-1+1)+(ymin-1)] - salmapIntegralImage[(scale+1)*(xmin-1)+(ymax-1+1)];                 
                 athr = thrmapIntegralImage[(scale+1)*(xmax-1 +1)+(ymax-1+1)] + thrmapIntegralImage[(scale+1)*(xmin-1)+(ymin-1)] - thrmapIntegralImage[(scale+1)*(xmax-1+1)+(ymin-1)] - thrmapIntegralImage[(scale+1)*(xmin-1)+(ymax-1+1)];                            
                 scoreScale[image_area * ((ymax-1)*scale+xmax-1)+((ymin-1)*scale+xmin-1)]=(aval*athr)/area;                 
               
              }

    return;
}
