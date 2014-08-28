function output = segment_fh(im, sigma, c, max_size)

% To make sure results are consistent with command line version, input should be scaled to 0-255
if(max(im(:))<=1)
   im = im*255;
end

% All types should be double
output = segment_fh_mex(double(im), double(sigma), double(c), double(max_size)); 
