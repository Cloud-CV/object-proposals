% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [val] = compute_sp_unary_values(abst_obj, seed_region)
    % convert from superpixel to pixel level seeds
    pxl_seed_region = ismember(abst_obj.seg_obj.sp_data.sp_seg, ...
                               find(seed_region));
    pxl_seed_region = pxl_seed_region(:);

    % compute affinities based on pixel seed region
    I = abst_obj.seg_obj.I;
    if(size(I, 3) ~= 3)
        I(:,:,2) = I(:,:,1);
        I(:,:,3) = I(:,:,1);
    end

    %val = obj.compute_unary_values_patch_rgb(seed_region);
    % compute inverse distance (capacity) for each pixel from seed region
    val = compute_unary_values_rgb(I, pxl_seed_region, ...
                                   abst_obj.graph_seed_frame_weight, ...
                                   abst_obj.graph_unary_exp_scale);
    
    % sum values over whole superpixels
    val = accumarray(abst_obj.seg_obj.sp_data.sp_seg(:), val);
end

function val = compute_unary_values_rgb(I, seed_region, multiplier, ...
                                        exp_scale)
    K = 5; % 10

    %%%%%% RGB space %%%%%%%%%%%
    pix = reshape(I, size(I,1)*size(I,2), 3);

    %%%%%%% HSV space %%%%%%%%%%%
    %pix = uint8(255*reshape(rgb2hsv(obj_I), size(obj_I,1)* size(obj_I,2), 3));

    %%%%%%% LAB space %%%%%%%%%%%%
    %pix = reshape(rgb2lab(obj_I), size(obj_I,1)* size(obj_I,2), 3);
    %pix(:,1) = pix(:,1)*2.55;
    %pix(:,[2 3]) = 255*((pix(:,[2 3]) + 110) / 220);
    %pix = uint8(pix);
    %t = tic();

    % get color values for the seed region
    seed_pix = pix(seed_region,:)';

    if K > size(seed_pix,2)
        K = size(seed_pix,2);
%        seed_pix = [seed_pix, seed_pix];
    end

    % get K representative colors from the seed region
    centers = vl_ikmeans(seed_pix, K, 'Method', 'lloyd');  % centers in columns!
    %toc(t);
    %obj.show_centers_colors(centers);

    %center = mean(double(pix_rgb(seed_region,:)));
    %dists = sum(abs(pix_rgb - center(ones(size(obj_I,1)* size(obj_I,2),1),:)),2);

    %ext_pix_rgb = pix(:,:,ones(K,1));

    dists = inf(size(pix,1),1);
    pix = single(pix);

    % compute the l1 norm of each pixel from one of the K cluster centers.
    % Store it if its the shortest distance seen so far
    for i=1:K
        center = single(centers(:,i)');
        dists = min(dists, sum(abs(bsxfun(@minus, pix, center)),2));
    end
    % exp(-dists x const) inverts the distance - high values will become 
    % low (values will range between 0 and 1)
    val = double(0.3 * multiplier * exp(-dists*exp_scale));
end
