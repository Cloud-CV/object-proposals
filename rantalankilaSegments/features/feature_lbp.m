function [words, k] = feature_lbp(I, opts)
% Calculates Local Binary Patterns for each pixel of an image.

I = single(rgb2gray(I));  % I is in rgb format regardless of colorspace argument for spagglom

SP = [-1 -1; -1 0; -1 1; 0 -1; -0 1; 1 -1; 1 0; 1 1];
I2 = lbp(I, SP, 0, 'i') + 1; % This is the lbp() function available from CMV website

k = max(I2(:));

words = zeros(size(I),'uint16');
words(2:end-1,2:end-1) = I2;    
words = words(:);



