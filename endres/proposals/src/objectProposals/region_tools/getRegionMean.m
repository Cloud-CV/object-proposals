function [vals, idx] = getRegionMean(idx, valim)
% [vals, idx] = getRegionMean(idx, valim)
%
% Gets mean(valim(idx{k})) for each set of indices.  If idx is not a cell,
% then gets idx as the PixelIdxList of idx using regionprops.


if ~iscell(idx)
    stats = regionprops(idx, 'PixelIdxList');
    idx = {stats.PixelIdxList};
end

vals = zeros(numel(idx), 1);
for k = 1:numel(idx)
    vals(k) = mean(valim(idx{k}));
end


