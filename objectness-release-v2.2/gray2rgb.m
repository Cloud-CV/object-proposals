function I = gray2rgb(I)

% converts graylevel image I to identical rgb image
% (useful for compatibility with certain algorithms
% which expect 3 color planes)
% 
% Do nothing if image is already rgb
%

if size(I,3) == 1
  I(:,:,3) = I;
  I(:,:,2) = I(:,:,3);
end
