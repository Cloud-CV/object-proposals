% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function precompute_pairwise_data(seg_obj)
    t_pair_precomp = tic;
    
    % get the indexes for the pairs of pixels to compute pairwise 
    %  potentials over
    [bndry_pairs, edgelet_ids, edgelet_sp] = ...
        Segmenter.generate_sp_neighborhood(seg_obj.sp_data.sp_seg);
    
    % store in the class
    seg_obj.sp_data.bndry_pairs = bndry_pairs;
    seg_obj.sp_data.edgelet_ids = edgelet_ids;
    seg_obj.sp_data.edgelet_sp = edgelet_sp;
 
%     if do_sp_pairwise_scaling
%         % compute the degree of each superpixel in the graph (number of
%         % neighboring superpixels)
%         deg_verts = accumarray(edgelet_sp(:), ...
%                                ones(numel(edgelet_sp),1));
% 
%         % adjust the contrast sensitive weight according to the average
%         % degree of the two superpixels sharing the edgelet. If the
%         % average degree is more than 4, then the contrast sensitive
%         % weight should be reduced, and vice verse. The number 4 comes
%         % from the average degree for a pixel level graph
%         deg_edgelet_sps = deg_verts(edgelet_sp);
%         avg_edgelet_deg = mean(deg_edgelet_sps,2);
%         edgelet_scaling = 4 ./ avg_edgelet_deg;
%         CONTRAST_SENSITIVE_WEIGHT = CONTRAST_SENSITIVE_WEIGHT .* ...
%                                     edgelet_scaling(edgelet_ids);
%     end

    bndry = seg_obj.bndry_data.bndry_thin;
    
    % make all values on the boundary positive
    if any(bndry(:) < 0)
        bndry = bndry + abs(min(bndry(:)));
    end

    % further adjust boundaries by looking at superpixels
    bndry = Segmenter.adjust_boundaries_sp(bndry, seg_obj.sp_data.sp_seg);

    % val can range [0, 255]
    val = intens_pixel_diff_mex(double(bndry), uint32(bndry_pairs(:,1)), ...
                                               uint32(bndry_pairs(:,2)));
    % intens_pixel_diff_mex is equivalent to:
    % gPb_dbl = double(gPb);
    % val = abs(gPb_dbl(ids(:,1)) - gPb_dbl(ids(:,2)));

    % setting median value for each edglet
    med_val = accumarray(edgelet_ids, val, [], @median) * 1;
    seg_obj.edge_vals = med_val(edgelet_ids);
    
    time_util(seg_obj, 'precompute_pairwise_time', t_pair_precomp, 0, 0);
end
