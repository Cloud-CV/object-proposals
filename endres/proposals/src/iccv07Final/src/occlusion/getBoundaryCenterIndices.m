function ind  = getBoundaryCenterIndices(bndinfo)
% ind  = getBoundaryCenterIndices(bndinfo)

ind = zeros(bndinfo.ne,1);
for k = 1:numel(ind)
    ind(k) = bndinfo.edges.indices{k}(ceil(end/2));
end



