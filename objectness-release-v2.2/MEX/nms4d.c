/* [xmin ymin xmax ymax score] = nms4d(score,width,height,M)  */

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
    double *score,*xmin,*ymin,*xmax,*ymax,*scoreLocalMaxim;
    int    width,height,M;
 
    /* Check for proper number of arguments */
    
    if (nrhs != 4) {
     mexErrMsgTxt("4 input arguments required.");
    } 
    else if (nlhs != 5) {
     mexErrMsgTxt("5 output arguments required");
    }

    if ( !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 2 )
		mexErrMsgTxt("input 1 (h) must be a real double matrix");
    

    score = mxGetPr(prhs[0]);/* score  */
    
    width = mxGetScalar(prhs[1]);
    height = mxGetScalar(prhs[2]);
    M = mxGetScalar(prhs[3]);

    int n = (M-1)/2;
    
    int numberMaximLocalMaxim = ceil((width*width*height*height)/((n+1)*(n+1)*(n+1)*(n+1)));

    /* Create a matrix for the return argument */
    
    plhs[0] = mxCreateDoubleMatrix(1,numberMaximLocalMaxim,mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,numberMaximLocalMaxim,mxREAL);
    plhs[2] = mxCreateDoubleMatrix(1,numberMaximLocalMaxim,mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1,numberMaximLocalMaxim,mxREAL);
    plhs[4] = mxCreateDoubleMatrix(1,numberMaximLocalMaxim,mxREAL); 
    xmin = mxGetPr(plhs[0]);
    ymin = mxGetPr(plhs[1]);
    xmax = mxGetPr(plhs[2]);
    ymax = mxGetPr(plhs[3]);
    scoreLocalMaxim = mxGetPr(plhs[4]);

    int i,j,k,l,mi,mj,mk,ml,i2,j2,k2,l2;
    double score_mi_mj_mk_ml = 0,score_i2_j2_k2_l2 = 0;

    int LocalMaxim = 0; 
    int currLocalMaxim = -1;
    /* Efficient Non-Maximum Suppression */
    for(i = 1;i <= width-n;i += n+1) 
       for(j = 1;j <= height-n;j += n+1)
          for(k = i;k <= width;k += n+1)
             for(l = j;l <= height;l += n+1) 
               {
                mi = i;mj = j;mk = k;ml = l;
                score_mi_mj_mk_ml = score[width*height*((ml-1)*width+mk-1)+((mj-1)*width+mi-1)];
                for(i2 = i;i2 <= i+n;i2++)
                   for(j2 = j;j2 <= j+n;j2++)
                      for(k2 = k;k2 <= MIN(k+n,width);k2++)
                         for(l2 = l;l2 <= MIN(l+n,height);l2++)
                            {                            
                            score_i2_j2_k2_l2 = score[width*height*((l2-1)*width+k2-1)+((j2-1)*width+i2-1)];
                            if(score_i2_j2_k2_l2>score_mi_mj_mk_ml)
                              {
                               mi = i2;
                               mj = j2;
                               mk = k2;
                               ml = l2;
                               score_mi_mj_mk_ml = score_i2_j2_k2_l2;
                              }
                            }
                 LocalMaxim = 1;
                 for(i2 = MAX(mi-n,1);i2 <= MIN(mi+n,width);i2++)
                   for(j2 = MAX(mj-n,1);j2 <= MIN(mj+n,height);j2++)
                      for(k2 = MAX(mk-n,1);k2 <= MIN(mk+n,width);k2++)
                         for(l2 = MAX(ml-n,1);l2 <= MIN(ml+n,height);l2++)
                            {
                             score_i2_j2_k2_l2 = score[width*height*((l2-1)*width+k2-1)+((j2-1)*width+i2-1)]; 
                             if(score_i2_j2_k2_l2 > score_mi_mj_mk_ml)
                               LocalMaxim = 0; 
                            }
                 if((LocalMaxim>0) && (score_mi_mj_mk_ml>0)) /* local maxima and not zero score  */
                    {
                     currLocalMaxim += 1;
                     xmin[currLocalMaxim] = mi;
                     ymin[currLocalMaxim] = mj;
                     xmax[currLocalMaxim] = mk;
                     ymax[currLocalMaxim] = ml;
                     scoreLocalMaxim[currLocalMaxim] = score_mi_mj_mk_ml;
                    }
                }
    
    return;
}
