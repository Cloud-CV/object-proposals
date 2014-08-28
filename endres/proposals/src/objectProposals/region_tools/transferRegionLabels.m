function [lab, labim, err] = transferRegionLabels(source, target)
% [lab, err] = transferRegionLabels(source, target)
% 
% Transfers pixel labels from source to target.  
%
% Input:
%  source(imh, imw): indices correspond to label or region number; 0 is "unassigned"
%  target(imh, imw): indices correspond to region number
% Output:
%  lab(nlabels): the source label for each region in target
%  labim(imh, imw): lab(target)
%  err: pixel error of source and labim  

t = regionprops(target, 'PixelIdxList');
targetidx = {t.PixelIdxList}; % pixel indices of each region in target

nlab = max(source(:));
lab = zeros(nlab, 1);

acc = 0;
for k = 1:numel(targetidx)    
    rlab = source(targetidx{k});  
    lab(k) = mode(rlab);
    if lab(k)==0 && any(rlab>0)  % assign to most common non-zero label
        lab(k) = mode(rlab(rlab>0));
    end
    if lab(k)~=0
        acc = acc + sum(rlab==lab(k));
    end            
end

if nargout>1
    labim = lab(target);
end

err = 1 - acc / sum(source(:)~=0);
