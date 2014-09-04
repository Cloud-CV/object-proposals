function ssave(name, varargin)
% SSAVE  Safe version of save
%  SSAVE() takes works as SAVE(), but it tries to prevent corruption
%  by unexpected termination of the MATLAB process. The command first
%  writes a file with the '.safe' extension and only then move the
%  file to its actual location.
%
%  Author:: Andrea Vedaldi

% AUTORIGHTS
% Copyright (C) 2008-09 Andrea Vedaldi
%
% This file is part of the VGG MKL Class and VGG MKL Det code packages,
% available in the terms of the GNU General Public License version 2.

if nargin < 1
  name = 'matlab.mat' ;
end

[a,b,c] = fileparts(name) ;

if ~isempty(a)
  ensuredir(a) ;
end

if length(c) < 4 || ~ strcmp(c(end-3:end),'.mat')
  name = [name '.mat'] ;
end

safeName = [name '.safe'] ;

cmd = sprintf(' %s', varargin{:}) ;
cmd = [sprintf('save ''%s''%s', safeName, cmd)] ;
evalin('caller', cmd) ;

if strcmp(computer, 'PCWIN') | strcmp(computer, 'PCWIN64')
  movefile(safeName, name) ;
else
  cmd = sprintf('mv -f ''%s'' ''%s''', safeName, name) ;
  [s,m] = system(cmd) ;
  if s
    warning(m) ;
  end
end