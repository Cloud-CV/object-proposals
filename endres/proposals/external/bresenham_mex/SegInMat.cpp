/*
%SegInMat 求矩阵中某线段上的所有元素
% 调用方式：
% elem = SegInMat(mat, rs, cs, re, ce)
% 输入：
%   mat:指定的矩阵
%   rs,cs:起点的行、列
%   re,ce:终点的行、列
% 输出：
%   elem:线段上所有点的值
%
*/
#include "mex.h"
#include "bresenham.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
                 const mxArray *prhs[])
{
  int len;  
  double rs, cs, re, ce;
  int *rr, *cc;
  double *p;
  int i;
  int row, col;
    
  /* Check for proper number of arguments. */
  if (nrhs != 5 || nlhs > 1) {
    mexErrMsgTxt("SegInMat::Invalid calling method...please type help LineTwoPntsInMat in"                  "command for help\n");
  } 
  rs = mxGetScalar(prhs[1]);
  cs = mxGetScalar(prhs[2]);
  re = mxGetScalar(prhs[3]);
  ce = mxGetScalar(prhs[4]);
  /* 获取所得线段的长度 */
  len = bresenham_len((int)rs, (int)cs, (int)re, (int)ce);
  rr = (int*)mxCalloc(len, sizeof(int));
  cc = (int*)mxCalloc(len, sizeof(int));
  
  
  /* 求线段上所有点 */
  bresenham((int)rs, (int)cs, (int)re, (int)ce, rr, cc);
  
  /* 
   * 将对应点上的值填入输出.
   * 注意！！Matlab中矩阵按列存储，下标从1开始。C中下标从0开始
   */
  
  int nrow = mxGetM(prhs[0]);
  int ncol = mxGetN(prhs[0]);

  // 注意：检查行列是否在范围内
  if ( rs > nrow || rs < 1
    || re > nrow || re < 1
    || cs > ncol || cs < 1
    || ce > ncol || ce < 1) 
  {
    mexErrMsgTxt("SegInMat::Input point out of range...\n");
  }
  else 
  {
    plhs[0] = mxCreateDoubleMatrix(1, len, mxREAL);
    p = mxGetPr(plhs[0]);
  }

  
  if (mxIsDouble(prhs[0])) {
    double* pmat = (double* )mxGetPr(prhs[0]);
    for (i = 0; i < len; ++i) {
      row = *(rr+i);
      col = *(cc+i);
      *(p+i) = (double)(*(pmat + (col-1)*nrow + row - 1));
    }
    return;
  }
  else {
    mexErrMsgTxt("SegInMat::Only supports double matrix\n" 
      "Try forced casting:\n"
      "SegInMat(double(mat),rs,cs, re,ce)\n"
      "Or use:\n"
      "  [rr,cc] = LineTwoPnts(rs,ce, re,ce);\n"
      "  idx     = sub2ind(rr,cc);\n"
      "  elems   = mat(idx);\n"
      "as alternative.");
  }
  
  

}