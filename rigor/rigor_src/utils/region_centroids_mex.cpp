// @authors:     Fuxin Li
// @contact:     fli@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "mex.h"
#include "matrix.h"
#include <math.h>

#ifdef _MSC_VER
#include <float.h>
#define INFINITY (DBL_MAX+DBL_MAX)
#define NAN (INFINITY-INFINITY)
#endif

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  unsigned int r, c, curr_lbl, idx, *num_each_lbl, lbl_iter = 0;
  double* centers_ptr;
  
  if (nrhs != 2) {
    mexErrMsgTxt("Needs 2 input variables: region_centroid_mex(label_mat, max_label) where label_mat is the label matrix, and max_label is the maximum number of labels");
  }
  if (nlhs != 1) {
    mexErrMsgTxt("Only outputs 1 variable: centers = region_centroid_mex(label_mat, max_label) where centers is a double array of Nx2 size giving the centroids for each label");
  }
  if (!mxIsUint32(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 2) {
    mexErrMsgTxt("The label_mat should be a matrix of type Uint32");
  }
  if (!mxIsDouble(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 1) {
    mexErrMsgTxt("The max_label is a single scalar");
  }
  
  unsigned int* label_mat = (unsigned int*)mxGetPr(prhs[0]);
  unsigned int max_label = (unsigned int)(*(double*)mxGetPr(prhs[1]));
  
  if (max_label < 1) {
    mexErrMsgTxt("max_label should be >= 1");
  }
  
  plhs[0] = mxCreateDoubleMatrix(2, max_label, mxREAL);
  centers_ptr = (double*)mxGetData(plhs[0]);
  
  num_each_lbl = (unsigned int*)mxCalloc(max_label, sizeof(unsigned int));
  
  size_t num_rows = mxGetM(prhs[0]);
  size_t num_cols = mxGetN(prhs[0]);
  
  /* iterate over all the rows and cols */
  for (c = 1; c <= num_cols; ++c) {
    for (r = 1; r <= num_rows; ++r, ++lbl_iter) {
      /* if the current pixel has a valid label */
      curr_lbl = label_mat[lbl_iter];
      if (curr_lbl != 0 && curr_lbl <= max_label) {
        idx = (curr_lbl-1)*2;
        /* add to total rows and cols */
        centers_ptr[idx] += r;
        centers_ptr[idx+1] += c;
        /* add to tally for the current label */
        ++num_each_lbl[curr_lbl-1];
      }
    }
  }
  
  for (r = 0; r < max_label; ++r) {
    idx = r*2;
    if (num_each_lbl[r] == 0) {
#ifdef _MSC_VER
      centers_ptr[idx] = NAN;
      centers_ptr[idx+1] = NAN;
#else
      centers_ptr[idx] = nan("");
      centers_ptr[idx+1] = nan("");
#endif
    } else {
      centers_ptr[idx] /= num_each_lbl[r];
      centers_ptr[idx+1] /= num_each_lbl[r];
    }
  }
  
  mxFree(num_each_lbl);
}