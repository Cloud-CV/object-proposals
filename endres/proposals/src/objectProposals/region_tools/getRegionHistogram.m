function rhist = getRegionHistogram(segmap, labmap, maxlab)
% rhist = getRegionHistogram(segmap, labmap, maxlab)
% 
% Gets the count for each integer value in labmap (all values must be
% greater than zero) for each region in segmap.  maxlab denotes the maximum
% label value.
%
% Output:
%   rhist(nregions, nlabels) - the histogram of labmap for each region


nseg = max(segmap(:));
rhist = zeros(nseg, maxlab, 'single');

for k = 1:numel(labmap)
   rhist(segmap(k), labmap(k)) = rhist(segmap(k), labmap(k))+1;
end
