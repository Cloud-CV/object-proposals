function [sp_data, t_sp] = compute_superpixels(orig_I, bndry_data, ...
                                               segm_params)
% compute superpixels using watershed, given the image and probablistic
% boundary estimates.
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    fprintf('Computing superpixels ... ');
    
    t_sp = tic;
    
    w_seg = watershed(bndry_data.bndry_fat);

%     gPb_fat{curr_img_idx} = imfilter(bndry_data.bndry_thin, fspecial('gaussian',[40 40], 1.2));
%     fsp = fspecial('gaussian', [30 30], 0.8);
%     gray_I = rgb2gray(orig_I{curr_img_idx});
%     w_seg = watershed(imfilter(gray_I, fsp));
%     w_seg = watershed(rgb2gray(orig_I{curr_img_idx}));
% 
%     img_lab = RGB2Lab(orig_I{curr_img_idx});

    % fill in the boundary pixels with the neighboring segment with
    % the closest RGB color
    sp_seg = fill_in_segmentation(orig_I, w_seg, 0, 4);

    % remove zeros (pixels which are still marked as boundaries)
    nghbrs = [-1 0 1];
    nghbrs = [nghbrs-size(w_seg,1), nghbrs, nghbrs+size(w_seg,1)];
    nghbrs(5) = [];
    zero_locs = find(sp_seg == 0);
    nghbrs = bsxfun(@plus, zero_locs, nghbrs);
    nghbrs = sp_seg(nghbrs);
    % setting it to mode, which is the most frequently occuring
    % superpixel in the neighborhood
    sp_seg(zero_locs) = uint16(mode(single(nghbrs), 2));

    % convert segmentation to double, since alot of things require
    % the values in double
    sp_seg = double(sp_seg);

    % compute the area (# of pixels) of each superpixel
    sp_seg_szs = accumarray(sp_seg(:), ones(numel(sp_seg),1));

    num_spx = max(sp_seg(:));
    
    % compute the centers for each SP
    sp_centroids = region_centroids_mex(uint32(sp_seg), num_spx)';
    
    % compute mean color for each SP
    lab = applycform(orig_I, makecform('srgb2lab'));
    pix = reshape(lab, size(orig_I,1)*size(orig_I,2), 3);
    r_avg = accumarray(sp_seg(:), pix(:,1)) ./ sp_seg_szs;
    g_avg = accumarray(sp_seg(:), pix(:,2)) ./ sp_seg_szs;
    b_avg = accumarray(sp_seg(:), pix(:,3)) ./ sp_seg_szs;
    sp_mean_clr = [r_avg, g_avg, b_avg];
    
    % compute std color for each SP
    r_std = accumarray(sp_seg(:), double(pix(:,1)).^2) ./ sp_seg_szs;
    g_std = accumarray(sp_seg(:), double(pix(:,2)).^2) ./ sp_seg_szs;
    b_std = accumarray(sp_seg(:), double(pix(:,3)).^2) ./ sp_seg_szs;
    sp_std_clr = ([r_std, g_std, b_std] - sp_mean_clr.^2) + eps;
    
    assert(~any(sp_seg_szs == 0), 'Some superpixel ids are missing');
    assert(min(sp_seg(:)) == 1, 'Superpixel ids dont start with 1');
    assert(num_spx == length(sp_seg_szs), ...
           'no_spx and sp_seg_szs inconsistent');
    
    sp_data.sp_seg = sp_seg;
    sp_data.sp_seg_szs = sp_seg_szs;
    sp_data.num_spx = num_spx;
    sp_data.sp_centroids = sp_centroids;
    sp_data.sp_mean_clr = sp_mean_clr;
    sp_data.sp_std_clr = sp_std_clr;
end