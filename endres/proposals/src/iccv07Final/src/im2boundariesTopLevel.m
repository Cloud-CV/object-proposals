function [bndinfo, pbim, gconf, bndinfo_all] = im2boundariesTopLevel(im, thresh)
%
% [bndinfo, pbim, gconf] = im2boundariesTopLevel(im, thresh)
%
% High level function for estimating boundaries in an image using Hoiem et
% al. 2007 occlusion reasonining method.  
%
% Inputs:
%   im:       RGB double format image
%   thresh:   threshold values for segmentation hierarchies (default =
%             [0.105 0.25 0.6], threshold is lowest boundary confidence 
%             required not to merge to regions in hierarchical segmentation
%
% Outputs:
%   bndinfo.wseg: the superpixels
%   bndinfo.edges.indices: the indices for each edge
%   bndinfo.result.edgeProb: probability of edge being on
%   bndinfo.result.geomProb: probabilty of geometric label (gnd, vert, sky)
%   bndinfo.result.boundaries: most likely ege label (0=off, 1=on)
%   pbim: probability of boundary (Pb) image (imh, imw, 4 orient) 
%   gconf: surface likelihoods (imh, imw, [support, vert-planar/L/C/R,
%          non-planar solid/porous])
% Notes:
%   - length of result.boundaries is twice length of edges.indices.  If
%   label in first half is "on", left side occludes; if label in second
%   half is "on", right side occludes.   


if ~exist('thresh', 'var') || isempty(thresh)
    thresh = [0.105 0.25 0.6];
end

if 0 
    load './tmp.mat'
%     tmp = gdata;
%     clear gdata
%     gdata.imsegs = tmp.imsegs;
%     clear tmp
else

% load classifiers
d = which('im2boundariesTopLevel.m');
d = d(1:end-length('im2boundariesTopLevel.m'));
load(fullfile(d, '../data/boundaryClassifiers.mat'));
load(fullfile(d, '../data/continuityClassifiers.mat'));
gclassifiers1 = load(fullfile(d, '../data/ijcvClassifier.mat'));
gclassifiers2 = load(fullfile(d, '../data/perfectSegClassifierCv.mat'));

% create pb confidences
disp('pb')
tic
pbim = pbCGTG_nonmax(im);
toc

% create geometric confidences
disp('geometry')
tic
%tmpbn = ['tmpim' num2str(ceil(rand(1)*1000000))];
%infn = ['./' tmpbn '.ppm'];
%imwrite(im, infn);
%outfn = ['./' tmpbn '.pnm'];
%syscall = [fullfile(d,'segment') ' 0.8 100 100 ' infn ' ' outfn];
[pg, tmp, imsegs] = ijcvTestImage2(im, {0.8, 100, 100}, gclassifiers1);
%delete(infn);
%delete(outfn);
clear tmp

gdata.imsegs = imsegs;
gconf = pg2confidenceImages(imsegs, {pg});
gconf = gconf{1}(:, :, 1:7);

toc
%save './tmp.mat'
end

% get occlusion boundary labels
disp('boundaries')
tic
[bndinfo, bndinfo_all] = im2boundaries(im, pbim, gconf, dtBnd, dtBnd_fast, dtCont, ...
    gdata, gclassifiers2, thresh);
toc
