function texim = getTextonImage(im, textonNodes)

if size(im, 3)==3
    im = rgb2gray(im);
end
feat = single(MRS4fast(imfilter(im, fspecial('gaussian', 3, 1))));
%idx = getNearestHierarchy(feat, textonNodes);
% leafnum = zeros(numel(textonNodes), 1);
% leafnum([textonNodes.isleaf]) = 1:sum([textonNodes.isleaf]);
% idx = leafnum(idx);

idx = getNearest(feat, textonNodes.centers);



texim = reshape(idx, size(im));
