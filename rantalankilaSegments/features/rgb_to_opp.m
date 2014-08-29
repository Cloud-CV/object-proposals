function im_opp = rgb_to_opp(im)
% Transforms image into opponent color space
% Code by Ross Girshick

if ~isa(im, 'double')
  im = double(im);
end

im_opp = zeros(size(im));
% Color saliency boosting? c1*0.850, c2*0.524, c3*0.065
im_opp(:,:,1) = (im(:,:,1) - im(:,:,2)) / sqrt(2);
im_opp(:,:,2) = (im(:,:,1) + im(:,:,2) - 2*im(:,:,3)) / sqrt(6);
im_opp(:,:,3) = sum(im,3) / sqrt(3);
%min(im_opp(:)) % about -50
%max(im_opp(:)) % about 450
im_opp = max(0, min(255, im_opp)); % is this a good idea?
