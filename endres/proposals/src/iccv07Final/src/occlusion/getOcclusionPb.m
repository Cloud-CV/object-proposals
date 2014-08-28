function pb = getOcclusionPb(bndinfo)
% pb = getOcclusionPb(bndinfo)

if isstruct(bndinfo)
    bndinfo = bndinfo{1};
end

maps = getOcclusionMaps(bndinfo);

ind = getBoundaryCenterIndices(bndinfo{1});
pb = zeros(numel(ind), numel(bndinfo));
for k = 1:numel(bndinfo)
    map = maps(:, :, k);
    pb(:, k) = map(ind);
end


