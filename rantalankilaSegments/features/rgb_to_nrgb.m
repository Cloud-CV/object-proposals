function im = rgb_to_nrgb(im)
% Transforms image into NRGB color space
% Code by Ross Girshick

if ~isa(im, 'double')
  im = double(im);
end
im = im./repmat(sum(im,3), [1 1 3]);

im = 255*im;
