function APPwriteVrmlModel(imdir, imseg, labels, vrmldir)            
% APPwriteVrmlModel(imdir, imseg, labels, vrmldir)      
% Computes a simple 3D model from geometry labels and writes to vrml file.
%
% Input: 
%   imdir: the directory of the source image
%   imseg: the sp structure for the image
%   labels: the geometric labels for the image
%   vmrldir: the directory for the vrml output
%
% Copyright(C) Derek Hoiem, Carnegie Mellon University, 2005
% Permission granted to non-commercial enterprises for
% modification/redistribution under GNU GPL.  
% Current Version: 1.0  09/30/2005

for i = 1:length(imseg)

	fn = imseg(i).imname;
	%disp(fn)
	image = im2double(imread([imdir '/' fn]));    
    
    if ~isfield(labels(i), 'hy') 
        if isfield(labels(i), 'horizy')
            labels(i).hy = labels(i).horizy;
        else
            %disp('re-estimating horizon line')
            lines = APPgetLargeConnectedEdges(rgb2gray(image), min([size(image, 1) size(image, 2)]*0.02), imseg(i));
            labels(i).hy = 1-APPestimateHorizon(lines);
            %disp(['horiz = ' num2str(labels(i).hy)])
        end
    end 
    
    if isempty(labels)
        vlabels = imseg(i).gvs_names(imseg(i).gvs+3*(imseg(i).gvs==0));
        %hlabels = imseg(i).lcrr_names(imseg(i).lcrr+4*(imseg(i).lcrr==0));
        hy = imseg(i).hy;
        hlabels = [];
    else
        vlabels = labels(i).vert_labels;
        %hlabels = labels(i).horz_labels;
        %vconf = labels(i).vert_conf;
        %hconf = labels(i).horz_conf;
        hlabels = [];
        hy = labels(i).hy;
    end

	
	bn = strtok(fn, '.');            
	imseg(i).segimage = imseg(i).segimage(26:end-25, 26:end-25);
    image = image(26:end-25, 26:end-25, :);

    %figure(2), imagesc(image);
    if 0 && ~exist([vrmldir '/' strtok(imseg(i).imname, '.') '.l.jpg'])
        lim = get_labeled_image_s(image, imseg(i), vlabels, ones(size(vlabels)), hlabels, hconf);
        imwrite(lim, [vrmldir '/' strtok(imseg(i).imname, '.') '.l.jpg']);
    end
	[gplanes, vplanes, gmap,vmap] = APPlabels2planes(vlabels, hlabels, hy, imseg(i).segimage, image);

    
    use_fancy_transparency = 1;
    if use_fancy_transparency
        vmap = conv2(double(vmap), fspecial('gaussian', 7, 2), 'same');
        vim = image;
        vim(:, :, 4) = vmap; % add alpha channel
    else
        vim = image;
        for b = 1:size(image, 3)
            vim(:, :, b) = image(:, :, b).*vmap;
        end
    end

    gim = image;    
    for b = 1:size(image, 3)
        gim(:, :, b) = gim(:, :, b) .* gmap;
    end    

	[points3D, tpoints2D, faces] = APPplanes2faces(gplanes, vplanes, [size(image, 1) size(image, 2)], hy);   
	faces2vrml(vrmldir, bn, points3D, tpoints2D, faces, gim, vim); %, gcolor, scolor);  
    
end