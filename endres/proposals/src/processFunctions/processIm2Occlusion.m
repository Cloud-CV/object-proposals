function [bndinfo, pbim, gconf, bndinfo_all] =  processIm2Occlusion(im, varargin)

%% Set parameters

%% Read image

if max(size(im))>640
  fprintf('Warning, this image is pretty big...\n');
  %im = imresize(im, 640/max(size(im)), 'bilinear');
end

%% Get occlusion info
[bndinfo, pbim, gconf, bndinfo_all] = im2boundariesTopLevel(im);
gconf = single(gconf);
pbim = single(pbim);

%save(outname, 'bndinfo', 'pbim', 'gconf', 'bndinfo_all');
