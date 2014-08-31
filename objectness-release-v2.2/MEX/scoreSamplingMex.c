/* indexSamples = scoreSamplingMex(score, samples, option);*/

#include <math.h>
#include "mex.h"

#if !defined(MAX)
#define    MAX(A, B)    ((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define    MIN(A, B)    ((A) < (B) ? (A) : (B))
#endif

void mexFunction( int nlhs, mxArray *plhs[],
          int nrhs, const mxArray *prhs[] )
     
{
    double *scoreVector, *scoreVectorCopy, *cumsum, *index, r;
    long int  numberSamples, option, lengthScoreVector, i, j, intervalLength, minim, maxim, middle;
    
    
    /* Check for proper number of arguments */
    
    if (nrhs != 3) {
     mexErrMsgTxt("3 input argument required: scoreVector, numberSamples, replacementOption ");
    } 
    else if (nlhs > 2) {
     mexErrMsgTxt("Too many output arguments.");
    }

    if ( !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 2 )
		mexErrMsgTxt("input 1 (X) must be a real double scoreVector");
 
    scoreVector = mxGetPr(prhs[0]);
    numberSamples = mxGetScalar(prhs[1]);
    option = mxGetScalar(prhs[2]);
    lengthScoreVector = MAX(mxGetN(prhs[0]),mxGetM(prhs[0])); 
    
    if((option == 0) && (numberSamples > lengthScoreVector))
                mexErrMsgTxt("numberSamples <= length scoreVector (sampling without replacement)");

    /* Create return arguments */
    
    plhs[0] = mxCreateDoubleMatrix(1,numberSamples,mxREAL);/* size of numberSamples*/  
    index = mxGetPr(plhs[0]);
   
    cumsum = mxGetPr(mxCreateDoubleMatrix(1,lengthScoreVector,mxREAL));
    scoreVectorCopy = mxGetPr(mxCreateDoubleMatrix(1,lengthScoreVector,mxREAL));
    cumsum[0] = scoreVector[0];
    for(i = 1;i < lengthScoreVector;i++)
        cumsum[i] = cumsum[i-1] + scoreVector[i];

    for(i = 0;i < lengthScoreVector;i++)
        scoreVectorCopy[i] = scoreVector[i];
    
    for(i = 0;i < numberSamples;i++)
     {
      r = ((double)rand() / ((double)(RAND_MAX)))*(cumsum[lengthScoreVector-1]); /* r between 0 and cumsum(end) */
      /*binary search */
      minim = 0;
      maxim = lengthScoreVector -1;
      intervalLength = maxim - minim +1;
       while(intervalLength >2)
        {
         middle = floor((minim+maxim)/2);
         if(cumsum[middle] > r)
           maxim = middle;
         else
           minim = middle;

         intervalLength = maxim - minim +1;
        }

       if(cumsum[minim] > r)
         index[i] = minim;
       else
         index[i] = maxim;
       if(option == 0)
         {
          j = floor(index[i]);
          scoreVectorCopy[j] = 0;
          cumsum[0] = scoreVectorCopy[0];
    	  for(j = 1;j < lengthScoreVector;j++) 
             cumsum[j] = cumsum[j-1] + scoreVectorCopy[j];
         }
     }
   for(i = 0;i < numberSamples;i++)
      index[i] = index[i]+1; 
   return;
}