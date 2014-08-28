#include <math.h>
#include <sys/types.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs != 3)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 1)
    mexErrMsgTxt("Wrong number of outputs");

  const int *dims = mxGetDimensions(prhs[0]);
  double *vals = (double *)mxGetPr(prhs[0]);
  double as = mxGetScalar(prhs[1]);
  double bs = mxGetScalar(prhs[2]);

  int n_r1s, n_r2s;


  const mxArray *r1_mxptr, *r2_mxptr;
  double *area = mxGetPr(prhs[2]);

   if(mxIsCell(prhs[0])) {
      n_r1s = mxGetNumberOfElements(prhs[0]);
   } else {
      n_r1s = 1;
   }

   if(mxIsCell(prhs[1])) {
      n_r2s = mxGetNumberOfElements(prhs[1]);
   } else {
      n_r2s = 1;
   }

   //printf("computing the overlap between %dx%d regions\n", n_r1s, n_r2s);
  mxArray *mxOut = mxCreateNumericMatrix(n_r1s, n_r2s, mxDOUBLE_CLASS, mxREAL);
  double *output = (double *)mxGetPr(mxOut);
  //plhs[0] = mxOut;
  // return;
   for(int r1 = 0; r1 < n_r1s; r1++) {
      if(!mxIsCell(prhs[0])) {
         r1_mxptr = prhs[0];
      } else {
         r1_mxptr = mxGetCell(prhs[0], r1);
      }
   
      int r1_length = mxGetNumberOfElements(r1_mxptr);
      double *r1_ptr = (double *)mxGetPr(r1_mxptr);

      double r1_area = 0;
      for(int i = 0; i < r1_length; i++)
         r1_area += area[(int)r1_ptr[i]-1];

      for(int r2 = 0; r2 <n_r2s; r2++) {
         if(!mxIsCell(prhs[1])) {
            r2_mxptr = prhs[1];
         } else {
            r2_mxptr = mxGetCell(prhs[1], r2);
         }
          
         int r2_length = mxGetNumberOfElements(r2_mxptr);
         //printf("R2 length: %d \n", r2_length);
         double *r2_ptr = (double *)mxGetPr(r2_mxptr);

         double r2_area = 0;
         double intersection = 0;
         int i1=0;
         for(int i = 0; i < r2_length; i++) {
            // Compute r2 area
            r2_area += area[(int)r2_ptr[i]-1];
            
            // Compute intersection of r1 and r2
            while(r1_ptr[i1] < r2_ptr[i] & i1 < (r1_length-1))
               i1++;
            
            if(r1_ptr[i1] == r2_ptr[i]) {
//               printf("They intersect! %f %f %d %d\n", r1_ptr[i1], r2_ptr[i], i1+1, i+1);
               intersection += area[(int)r2_ptr[i]-1];
            }
         }

         //printf("Region %d, %d: with areas: %f %f, and intersection: %f\n", r1, r2, (float)r1_area, (float)r2_area, (float)intersection);
         output[r1 + n_r1s*r2] = intersection/(r1_area + r2_area - intersection);
      }
  }

  plhs[0] = mxOut;
}
