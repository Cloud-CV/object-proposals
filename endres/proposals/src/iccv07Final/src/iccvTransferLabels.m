function [lab, err] = iccvTransferLabels(labels, regions, area)
% [lab, err] = transferLabels(labels, regions, area)
  


nlab = max(labels);

nr = numel(regions);
lab = zeros(nr, 1);

npix = sum(area.*(labels>0));
total = 0;

count = zeros(nr,1);
for k = 1:nr
    count(k) = sum(labels(regions{k})>0);
end
for k = find(count==1)'
    valid = labels(regions{k})>0;
    lab(k) = labels(regions{k}(valid));
    total = total + area(regions{k}(valid));
end

for k = find(count>1)'
    rcount = zeros(nlab, 1);
    origlabs = labels(regions{k});
    valid = find(origlabs>0);        
    for k2 = valid(:)'
        rcount(origlabs(k2)) = rcount(origlabs(k2)) + area(regions{k}(k2)); 
    end
    [tmp, lab(k)] = max(rcount);   
    total = total + tmp;
end

err = (npix-total) / npix;

