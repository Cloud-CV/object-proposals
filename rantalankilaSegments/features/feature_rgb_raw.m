function [words, k] = feature_rgb_raw(I, I_type, opts)
% Partitions the RGB color cube into cubes of equal size and uses them as
% histogram bins. Returns the bins for each pixel.

if ~strcmp(I_type, 'rgb')
    error('feature_rgb_raw requires RGB image');
end
    
n = 32; % 32 default
assert(mod(256,n) == 0); % bins of equal size
z = 256/n;

edges = n*(0:256/n); % This is valid for rgb-format images only!

[~, bin1] = histc(I(:,:,1), edges);
[~, bin2] = histc(I(:,:,2), edges);
[~, bin3] = histc(I(:,:,3), edges);

% Stretch the 3dim histogram to one dimensional
comb = 1 + (z^2)*(bin1-1) + z*(bin2-1) + (bin3-1);

% These two produce the same results - using default matlab funcs there
% should be no danger of concatenating rows instead of columns and mixing
% up the indices.
words = comb(:);
%words = reshape(comb, size(comb,1)*size(comb,2), 1);

k = z^3;

% Shows that there is no indexing error
% words(1:20)
% words = reshape(words, size(I,1), size(I,2));
% image(words) % pixels in correct places, original image distinguishable
% words2 = words(:); % this reverses the above reshape...
% words2(1:20) % ... because this is equal to above words(1:20)





    