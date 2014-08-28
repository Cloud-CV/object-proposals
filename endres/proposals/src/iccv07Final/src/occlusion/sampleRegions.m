function [regions, scores] = sampleRegions(pB, spLR, seg, niter, maxov, nregions)

stats = regionprops(seg, 'Area');
area = [stats.Area];
area = area / sum(area);

updateFactor = 0.9;

nsp = numel(area);

scores = cell(niter+1,1);
regions = cell(niter+1, 1);

pB2 = pB;

% get regions through hierarchical segmentation
for k = 1:niter
    
    %pB2 = pB2-min(pB2);  pB2 = pB2 / max(pB2); % normalize 0 to 1
    hier = boundaries2hierarchy(pB2, spLR, 'max', [], [], pB);
    if k==1
        [scores{k}, scoresSp] = getHierarchyRegionScores(hier);
        scores{niter+1} = scoresSp;
        regions{niter+1} = num2cell(1:nsp)'; % superpixel regions
    else
        % assign costs according to original boundary likelihoods
%         for k2 = 1:nsp-1
%             hier.thresh(k2) = max(pB(hier.edges_removed{k2}));
%         end
        scores{k} = getHierarchyRegionScores(hier);
    end
    regions{k} = hier.new_region;
    
%     if k>1
%         ts = [scores{k} ; scores{1}];
%         [sval, sind] = sort(ts, 'descend');
%         sum(sind(1:50)<=numel(scores{k}))
%     end
    
    % decrement likelihoods of boundaries that are removed late
    for k2 = 1:nsp-1
        pB2(hier.edges_removed{k2}) = pB2(hier.edges_removed{k2}) * updateFactor^(k2/(nsp-1));
        %pB2(hier.edges_removed{k2}) = pB2(hier.edges_removed{k2}) + rand(1)*0.05;
    end
end

iterind = cell(numel(scores), 1);
for k = 1:numel(scores)
    iterind{k} = k*ones(numel(scores{k}), 1);
end
iterind = cat(1, iterind{:});
    
scores = cat(1, scores{:});
regions = cat(1, regions{:});

for k = 1:numel(regions)
    scores(k) = scores(k) * sqrt(sum(area(regions{k})));
end

if isempty(nregions)
    return;
end
    

coverage = zeros(nsp, 1);
cov = zeros(nregions, 1);
isselected = false(numel(regions), 1);

[scores, sind] = sort(scores, 'descend');
regions = regions(sind);

% take top nregion regions that do not overlap too much
rind = zeros(nregions,1);
n = 0;
for k1 = 1:numel(regions)
    isov = false;
    for k2 = 1:k1-1
        if isselected(k2) && (regionOverlap(regions{k1}, regions{k2}, area) > maxov)
            isov = true;            
            break;
        end
    end
    if ~isov
        n=n+1;
        coverage(regions{k1}) = coverage(regions{k1}) + 1;
        isselected(k1) = true;
        cov(n) = sum(area(coverage>0))/sum(area);
        rind(n) = k1;
        if n==nregions
            break;
        end
    end
end
%regions = regions(rind(1:n));

iterind = iterind(sind);
for k = 1:max(iterind)
    disp([num2str(k) ': ' num2str(sum(iterind(rind)==k))]);
end

rind2 = zeros(sum(coverage==0), 1);
n2 = 0;
if any(coverage==0)
    for k = 1:numel(regions)
        if any(coverage(regions{k})==0)
            n2 = n2 +1;
            rind2(n2) = k;
            coverage(regions{k}) = coverage(regions{k})+1;
            if ~any(coverage==0)
                break;
            end
        end
    end
end

regions = regions([rind(1:n) ; rind2(1:n2)]);
scores = scores([rind(1:n) ; rind2(1:n2)]);

disp(mean(scores))








