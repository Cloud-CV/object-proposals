function [bndinfo, bndinfo_all] = im2boundaries(im, pbim, gconf, dtBnd, dtBnd_fast, dtCont, ...
    gdata, gclassifiers, thresh)
%
% bndinfo = im2boundaries(im, pbim, gconf, dtBnd, dtBnd_fast, dtCont, gdata, gclassifiers)
%                        
% Finds occluding contours for im.
%
% Input:
%   im: hxwx3 RGB image
%   pbim:  hxwx4 low level probability of boundary (for four orientations)
%   gconf: hxwx7 geometric context likelihoods
%   dtBnd: 1x3 boundary classifiers for each stage
%   dtBnd_fast: 1x3 fast boundary classifiers for each stage
%   dtCont: 1x3 continuity classifiers for each stage (first is empty)
%   gdata.imsegs: the superpixel structure for the geometric context classifers
%   gclassifiers: the geometric context classifiers
%   thresh: 1x3 thresholds for region merging (default = [0.105 0.25 0.6])
%
% Output:
%   bndinfo.wseg: the superpixels
%   bndinfo.edges.indices: the indices for each edge
%   bndinfo.result.edgeProb: probability of edge being on
%   bndinfo.result.geomProb: probabilty of geometric label (gnd, vert, sky)
%   bndinfo.result.boundaries: most likely ege label (0=off, 1=on)
%
% Notes:
%   - length of result.boundaries is twice length of edges.indices.  If
%   label in first half is "on", left side occludes; if label in second
%   half is "on", right side occludes.  
%

global DO_DISPLAY;

DO_DISPLAY = 0;

if ~exist('thresh', 'var') || isempty(thresh)
    thresh = [0.105 0.25 0.6];
end


%% Create bndinfo structure
wseg = pb2wseg(pbim, 100000);
        
[edges, juncts, neighbors, wseg] = seg2fragments(double(wseg), im, 25);
bndinfo = processBoundaryInfo(wseg, edges, neighbors);

gdata.imsegs = bndinfo2imsegs(bndinfo, gdata.imsegs);


%% Do iter 1 (min merge from local boundary classification)
bndinfo_all{1} = bndinfo;
s = 1;
X = getFeatures(bndinfo, im, pbim, gconf);
[result, pbnd] = mergeStageMin(X, bndinfo, dtBnd(s), dtBnd_fast(s), 2, thresh(s));
bndinfo = updateBoundaryInfo(bndinfo, result, im);  
bndinfo_all{1}.pbnd = pbnd{1};
bndinfo_all{2} = bndinfo;

%% Do iter 2 (min merge after CRF inference)

s = 2;
X = getFeatures(bndinfo, im, pbim, gconf);
[result, pbnd] = mergeStageBp(X, bndinfo, dtBnd(s), dtBnd_fast(s), dtCont(s), thresh(s));
bndinfo = updateBoundaryInfo(bndinfo, result, im); 
bndinfo_all{2}.pbnd = pbnd{1};
bndinfo_all{3} = bndinfo;

%% Do iter 3..N (min merge after CRF inference, including geometry)

s = 3;

bndinfotmp = bndinfo;
bndinfotmp.labels = (1:bndinfo.nseg);
bndinfotmp = transferSuperpixelLabels(bndinfotmp, wseg);    
segmaps = bndinfotmp.labels;

[bndinfo, lab, plab_e, plab_g, pbnd] = mergeStageFinalBpGeometry(...
    bndinfo, dtBnd(s), dtBnd_fast(s), dtCont(s), thresh(s), ...
    im, pbim, gconf, gdata, gclassifiers, segmaps, wseg);

bndinfo.edges.boundaryType = lab;
bndinfo.result.edgeProb = plab_e;
bndinfo.result.geomProb = plab_g;
bndinfo.result.boundaries = lab;
bndinfo.result.thresh = thresh;

bndinfo_all{3}.pbnd = pbnd;
bndinfo_all{4} = bndinfo;