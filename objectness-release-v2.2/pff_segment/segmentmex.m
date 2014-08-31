function varargout = segmentmex(varargin)
% [LABEL_IMAGE,N] = SEGMENTMEX(IMG,SIGMA,K,MIN)
% 
% Inputs:
%  - IMG: the input image (uint8 format).
%  - SIGMA, K, MIN: parameters of the algorithm (cf README)
%
% Output:
%  - LABEL_IMAGE has the same size as IMG and contain a uint32 superpixel id for each pixel (not continuous and not starting at 1. cf README)
%  - N the number of superpixels
%

ext_source = '.cpp';
ext_mex = mexext;
funcName = mfilename;
fileName = mfilename('fullpath');
sourceName = [ fileName ext_source ];
mexName = [ fileName '.' ext_mex ];
fprintf('compiling %s\n',mexName);
mex(sourceName,'-output',mexName);
varargout=cell(nargout,1);
[varargout{:}] = feval(funcName,varargin{:});
