function covering = getBestCovering(seg, regions, spseg, do_approx)
% covering = getBestCovering(seg, regions, spseg)
%
% Computes covering of seg by regions, where seg is an image with indices
% denoting a partitioning and regions is a cell array containing indices
% into spseg specifying image regions.
%
% covering.pix = covering weighted by pixel area of seg regions
% covering.unweighted = average covering (unweighted)

if ~exist('do_approx', 'var')
    do_approx = 0;
end

covering.maxov = zeros(max(seg(:)), 1);
covering.maxr = zeros(max(seg(:)), 1);
covering.area = 0;
covering.pix = 0;
covering.unweighted = 0;


rmap = false(max(spseg(:)), 1);
if do_approx % approximates seg with spseg
    s = regionprops(spseg, 'Area');
    area = cat(1, s.Area);  area = area/sum(area);    
    lab = transferRegionLabels(seg, spseg);
    for r1 = 1:max(lab)
        region1 = find(lab==r1);        
        maxov = 0;
        maxr = 0;        
        for r2 = 1:numel(regions)
            ov = regionOverlap(region1, regions{r2}, area);
            if ov > maxov
                maxov = ov;
                maxr = r2;
            end
        end
        if maxr~=0
            rmap(:) = false;
            rmap(regions{maxr}) = true;
            region1 = seg==r1;
            region2 = rmap(spseg);
            ov = sum(region1(:) & region2(:)) / sum(region1(:) | region2(:));        
            covering.maxov(r1) = ov;
            covering.pix = covering.pix + ov * mean(region1(:));  
            covering.unweighted = covering.unweighted + ov / max(seg(:));  
            covering.area (r1) = mean(region1(:));
            covering.maxr(r1) = maxr;
        end
                
    end
else
    stats = regionprops(spseg, 'Area');
    area = cat(1, stats.Area);
    seg(seg<0) = 0;
    stats = regionprops(seg, 'Area');
    segarea = cat(1, stats.Area);
    nsp = numel(area);
    nseg = max(seg(:));
    count = zeros(nsp, nseg);
    ind = find((spseg > 0) & (seg>0));
    for k = ind(:)'
       s1 = spseg(k);
       s2 = seg(k);
       count(s1, s2) = count(s1, s2)+1;
    end
    for r1 = 1:nseg        
        maxr = 0;
        maxov = 0;           
        for r2 = 1:numel(regions)         
	    region = regions{r2}; region = region(region<nsp);  
            intersection = sum(count(region, r1));
            union = sum(area(region)) + segarea(r1) - intersection;
            ov = intersection / union;                                    
            if ov > maxov
                maxr = r2;
                maxov = ov;
            end
        end
        covering.maxr(r1) = maxr;
        covering.regions{r1} = regions{maxr};
        covering.maxov(r1) = maxov;
        covering.area(r1) = segarea(r1)/numel(seg);
        covering.pix = covering.pix + segarea(r1)*maxov/sum(segarea);  
        covering.unweighted = covering.unweighted + maxov / nseg;        
    end  
    
%     rmap = false(max(spseg(:)), 1);
%     for r1 = 1:max(seg(:))
%         region1 = seg==r1;        
%         maxov = 0;   
%         for r2 = 1:numel(regions)           
%             rmap(:) = false;
%             rmap(regions{r2}) = true;
%             region2 = rmap(spseg);
%             ov = sum(region1(:) & region2(:)) / sum(region1(:) | region2(:));
%             if ov > maxov
%                 maxov = ov;
%             end
%         end
%         covering = covering + mean(region1(:))*maxov;  
%     end  
end
