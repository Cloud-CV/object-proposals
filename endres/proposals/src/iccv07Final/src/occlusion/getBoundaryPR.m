function [P,R,thresh, cntR,sumR,cntP,sumP] = getBoundaryPR(pb, segs, maxdist, nthresh)
% [P,R,thresh, F, cntR,sumR,cntP,sumP] = getBoundaryPR(pb, segs, maxdist,nthresh)
%
% Calcualte precision/recall curve using faster approximation.
% If pb is binary, then a single point is computed with thresh=0.5.
% The pb image can be smaller than the segmentations.
%
% INPUT
%	pb		Soft or hard boundary map.
%	segs		Ground truth segmentation maps.
%	[nthresh]	Number of points in PR curve.
%
% OUTPUT
%	thresh		Vector of threshold values.
%	cntR,sumR	Ratio gives recall.
%	cntP,sumP	Ratio gives precision.
%
% See also boundaryPR.
% 
% Originally from David Martin <dmartin@eecs.berkeley.edu>, January 2003
% Modified by Derek Hoiem, June 2009 for general use

brd = 10; % border width (ignore pixels near border)
pb(:, [1:brd end-brd+1:end]) = 0;
pb([1:brd end-brd+1:end], :) = 0;

do_thin = true;
if nargin<3
    maxdist = 0.01;
end

if nargin<4, nthresh = 100; end

nthresh = max(1,nthresh);

[height,width] = size(pb);
nsegs = length(segs);
thresh = linspace(1/(nthresh+1),1-1/(nthresh+1),nthresh)';

% compute boundary maps from segs
bmaps = cell(size(segs));
for i = 1:nsegs,
  bmaps{i} = double(seg2bmap(segs{i},width,height));
  
  % remove boundaries near borders
  bmaps{i}(:, [1:brd end-brd+1:end]) = 0;
  bmaps{i}([1:brd end-brd+1:end], :) = 0;
end

% thin everything
if do_thin
for i = 1:nsegs,
  bmaps{i} = bmaps{i} .* bwmorph(bmaps{i},'thin',inf);
end
end

% compute denominator for recall
sumR = 0;
for i = 1:nsegs,
  sumR = sumR + sum(bmaps{i}(:));
end
sumR = sumR .* ones(size(nthresh));
  
% zero counts for recall and precision
cntR = zeros(size(thresh));
cntP = zeros(size(thresh));
sumP = zeros(size(thresh));

%fwrite(2,'[');
for t = nthresh:-1:1,
%  fwrite(2,'.');
  % threshold and then thin pb to get binary boundary map
  bmap = (pb>=thresh(t));
  if do_thin
    bmap = double(bwmorph(bmap,'thin',inf));
  end
  if t<nthresh,
    % consider only new boundaries
    bmap = bmap .* ~(pb>=thresh(t+1));
    % these stats accumulate
    cntR(t) = cntR(t+1);
    cntP(t) = cntP(t+1);
    sumP(t) = sumP(t+1);
  end 
  % accumulate machine matches across the human segmentations, since
  % the machine pixels are allowed to match with any segmentation
  accP = zeros(size(pb));
  % compare to each seg in turn
  for i = 1:nsegs,
    % compute the correspondence
    [match1,match2] = correspondPixels(bmap,bmaps{i},maxdist);
    % compute recall, and mask off what was matched in the groundtruth
    cntR(t) = cntR(t) + sum(match2(:)>0);
    bmaps{i} = bmaps{i} .* ~match2;
    % accumulate machine matches for precision
    accP = accP | match1;
  end
  % compute precision
  sumP(t) = sumP(t) + sum(bmap(:));
  cntP(t) = cntP(t) + sum(accP(:));
end

R = cntR ./ (sumR + (sumR==0));
P = cntP ./ (sumP + (sumP==0));


%fprintf(2,']\n');
