function labels = getBoundaryGt(bmap, gt, maxdist)
% labels = getBoundaryGt(bmap, gt)
%
% Computes ground truth labels for bmap given gt, which can be a boundary
% map or a segmentation map

warning('this function does not work correctly')

[imh, imw] = size(bmap);

bmap = bmap>0;
bmap = double(bwmorph(bmap,'thin',inf));

if islogical(gt) || max(gt(:))==1
    gtbmap = gt;
else
    gtbmap = double(seg2bmap(gt,imw, imh));
    gtbmap = gtbmap .* bwmorph(gtbmap,'thin',inf);    
end

[match1,match2] = correspondPixels(bmap,gtbmap,maxdist);

tp = match1 > 0;
labels = single(tp) + -1*single(~tp & bmap);

