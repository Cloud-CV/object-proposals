function colorim = getColorImage(im, colorNodes)
% colim = getColorImage(im, colorNodes)

[L, a, b] = rgb2lab(im);


feat = single(cat(2, L(:)/2, a(:), b(:))/100); 

idx = getNearest(feat, colorNodes.centers);

colorim = reshape(idx, [size(im, 1) size(im, 2)]);
