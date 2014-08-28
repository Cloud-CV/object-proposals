%SegInMat return all the elments of a segment within a matrix
% usage£º
% elems = SegInMat(mat, rs, cs, re, ce)
% IMPORTANT:only double matrix is supported. Use forced casting if
% necessary
% Or use:
%   [rr,cc] = LineTwoPnts(rs,ce, re,ce);
%   idx     = sub2ind(rr,cc);
%   elems   = mat(idx);
% as alternative.
%
% input£º
%   mat: input matrix
%   rs,cs: row and column of start point
%   re,ce: row and column of end point
% output£º
%   all the elements of segment (rs,cs)->(re,ce) within matrix mat
%
% for example:
% ------------
%
% mat = reshape([1:18], 3, 6);
% elems = SegInMat(mat, 1,1, 3,5);
%
