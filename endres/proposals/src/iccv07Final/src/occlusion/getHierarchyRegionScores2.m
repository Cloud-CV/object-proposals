function [scores, scoresSp] = getHierarchyRegionScores2(hier, pB, spLR)
% scores = getHierarchyRegionScores2(hier, pB, spLR)
%
% Gets score for each region in hier (note that this excludes the
% superpixels or atomic regions).  
% score(region) = (1-max_interior_Pb)*min_exterior_Pb
% scoresSp are the scores of the original superpixels
%
nr = numel(hier.thresh);
ne = numel(pB);

scoresSp = zeros(nr+1, 1);
e_interior = false(ne, nr+1);
e_exterior = false(ne, nr+1);
for k = 1:nr+1
    e_exterior(:, k) = spLR(:, 1)==k | spLR(:, 2)==k;
    scoresSp(k) = min(pB(e_exterior(:, k)));
end
    
scores = zeros(nr, 1);
for k = nr:-1:1  % step backwards through hierarchy
    
    rnew = hier.new_index(k);
    rold = hier.old_index(k);
    e_interior(:, rnew) = e_interior(:, rnew) | e_interior(:, rold);
    e_interior(hier.edges_removed{k},rnew)=1;
    e_exterior(:, rnew) = e_exterior(:, rnew) | e_exterior(:, rold);
    e_exterior(:, rnew) = e_exterior(:, rnew) & ~e_interior(:, rnew);    
    
    scores(k) = (1-max(pB(e_interior(:, rnew))))*min(pB(e_exterior(:, rnew)));
    
end



