% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [val] = compute_sp_mean_unary_values(abst_obj, seed_region)
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
    val = compute_bhtt_unary_values_rgb(I, pxl_seed_region, seed_region, ...
                                        abst_obj.seg_obj.sp_data, ...
                                        abst_obj.graph_seed_frame_weight, ...
                                        abst_obj.graph_unary_exp_scale);
    
    % scale up by superpixel size
    val = (val .* abst_obj.seg_obj.sp_data.sp_seg_szs) ./ 3;
end

function val = compute_mean_unary_values_rgb(I, pxl_seed_region, ...
                                             seed_region, sp_data, ...
                                             multiplier, exp_scale)
    mean_clrs = sp_data.sp_mean_clr(:,[2 3]);
    
    centers = mean_clrs(seed_region,:);
    
    % reshape matrices for bsxfun
    centers = reshape(centers, 1, size(centers,1), 2);
    mean_clrs = reshape(mean_clrs, size(mean_clrs,1), 1, 2);
    
    % find the l1 norm across all different centers
    dists = sum(abs(bsxfun(@minus, mean_clrs, centers)), 3);
    % pick the distance which is the smallest
    dists = min(dists, [], 2);
    
    % exp(-dists x const) inverts the distance - high values will become 
    % low (values will range between 0 and 1)
    val = double(0.3 * multiplier * exp(-dists*exp_scale));
end

function val = compute_bhtt_unary_values_rgb(I, pxl_seed_region, ...
                                             seed_region, sp_data, ...
                                             multiplier, exp_scale)
    mean_clrs = sp_data.sp_mean_clr;
    var_clrs = sp_data.sp_std_clr;
    
    centers = mean_clrs(seed_region,:);
    varcs = var_clrs(seed_region,:);
    
    % reshape matrices for bsxfun
    centers = reshape(centers, 1, size(centers,1), 3);
    varcs = reshape(varcs, 1, size(varcs,1), 3);
    mean_clrs = reshape(mean_clrs, size(mean_clrs,1), 1, 3);
    var_clrs = reshape(var_clrs, size(var_clrs,1), 1, 3);
    
    % compute Bhattacharya distance individually for each dimension as
    % given in http://en.wikipedia.org/wiki/Bhattacharyya_distance
    temp = bsxfun(@rdivide, varcs, var_clrs);
    temp = log(0.25 .* (temp + 1./temp + 2));
    temp2 = (bsxfun(@minus, mean_clrs, centers).^2) ./ ...
            (bsxfun(@plus, var_clrs, varcs));
    dists = sum(0.25 .* (temp + temp2), 3);
    dists = min(dists, [], 2);
%     
%     % find the l1 norm across all different centers
%     dists = sum(abs(bsxfun(@minus, mean_clrs, centers)), 3);
%     % pick the distance which is the smallest
%     dists = min(dists, [], 2);
    
    % exp(-dists x const) inverts the distance - high values will become 
    % low (values will range between 0 and 1)
    val = double(0.3 * multiplier * exp(-dists*exp_scale));
end