function rmaps = thresholdHierarchy(hier, thresh)

[thresh, sind] = sort(thresh);
nsp = numel(hier.new_index)+1;
nthresh = numel(thresh);

rmap = 1:nsp;
rmaps = zeros(nsp, nthresh);

n = 1;

for k = 1:nsp-1
    while hier.thresh(k) >= thresh(n)     
        % make sure region numbers are consecutive
        unique_r = unique(rmap);
        %disp(numel(unique_r))
        mapping = zeros(1, nsp);
        mapping(unique_r) = 1:numel(unique_r);                
        rmaps(:, sind(n)) = mapping(rmap); 
        if n==nthresh
            return;
        end        
        %disp(num2str([hier.thresh(k) thresh(n)]))
        n=n+1;        
    end
    
    rmap(hier.new_region{k}) = hier.new_index(k);
end
rmaps(:, n+1:end) = 1;
    
