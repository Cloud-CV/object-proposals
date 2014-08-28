function [scores, scoresSp] = getHierarchyRegionScores(hier)
% scores = getHierarchyRegionScores(hier)
%
% Gets score for each region in hier (note that this excludes the
% superpixels or atomic regions).  
% score(region) = cost_to_merge(region) * (1-cost_of_merge(region))
%  where cost_of_merge is the threshold at which the region is created, and
%  cost_to_merge is the threshold at which the region is merged into
%  another.  For instance, this could be the confidence of the strongest
%  exterior boundary times one minus the confidence of the strongest
%  interior boundary.
% scoresSp are the scores of the original superpixels
%
nr = numel(hier.cost);
scores = zeros(nr, 1);
merger = zeros(nr, 1);

for k = nr:-1:1  % step backwards through hierarchy
    
    scores(k) = (1-hier.cost(k)); % get cost of merge
    %scores(k) = 1;
    
    % get cost to merge
    if k~=nr
        scores(k) = scores(k)*hier.cost(merger(hier.new_index(k)));
        merger(hier.new_index(k)) = 0;
    end
    
    % record when previous regions will be merged 
    merger(hier.old_index(k)) = k;    
    merger(hier.new_index(k)) = k; 
end

if nargout>1
    ind = merger>0;
    %scoresSp = zeros(nr+1, 1);
    scoresSp = hier.cost(merger(ind));
    %max(scoresSp)
end

