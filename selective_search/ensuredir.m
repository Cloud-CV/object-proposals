function ensuredir(path)
% ENSUREDIR  Make sure a directory exists.
%  ENSUREDIR(PATH) check for the existence of the directory
%  PATH and attempt to create it otherwise.
%
%  Author:: Andrea Vedaldi

% AUTORIGHTS
% Copyright (C) 2008-09 Andrea Vedaldi
%
% This file is part of the VGG MKL Class and VGG MKL Det code packages,
% available in the terms of the GNU General Public License version 2.

if isempty(path)
  return
end

[subpath, name, ext] = fileparts(path) ;
name = [name ext] ;

if ~strcmp(subpath, path)
  ensuredir(subpath) ;
end

if ~exist(path, 'dir')
  mkdir(subpath, name) ;
end
