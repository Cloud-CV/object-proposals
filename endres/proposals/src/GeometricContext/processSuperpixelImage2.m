function imsegs = processSuperpixelImage(fn)
% imsegs = processSuperpixelImage(fn)
% Creates the imsegs structure from a segmentation image
%
% INPUT: 
% fn - 1 or 3 channel pixel maps of segmentation images. 
% Segments are denoted by different RGB/Grayscale colors.  
%
% OUTPUT:
% imsegs - image segmentation data 
%
% Copyright(C) Derek Hoiem, Carnegie Mellon University, 2006

          
if ~iscell(fn)
    fn = {fn};
end

imsegs(length(fn)) = struct('imname', '', 'imsize', [0 0]);
for f = 1:length(fn)    
    im = double(fn{f});
    
    imsegs(f).imname = [];
    imsegs(f).imsize = size(im);
    imsegs(f).imsize = imsegs(f).imsize(1:2);
    if(size(im,3)==3) % i.e. the raw output of FH segmentation
       im = im(:, :, 1) + im(:, :, 2)*256 + im(:, :, 3)*256^2;
    end

    [gid, gn] = grp2idx(im(:));
    imsegs(f).segimage = uint16(reshape(gid, imsegs(f).imsize));
    imsegs(f).nseg = length(gn);
end
imsegs = APPgetSpStats(imsegs);

