function map = getSubRegions(seg1, seg2)
% map = getSubRegions(seg1, seg2)
% 
% For each region (denoted by index) in seg1, gives the corresponding
% region in seg2.  seg2 must be a strict partitioning of seg1 (all pixels
% in a given seg1 region must be in a single seg2 region).


nseg = max(seg1(:));
map = zeros(nseg, 1);
map(seg1) = seg2;

%stats = regionprops(seg1, 'PixelIdxList');
%idx = {stats.PixelIdxList};
% for k = 1:numel(idx)
%     map(k) = seg2(idx{k}(1));
% end
   
    
    


