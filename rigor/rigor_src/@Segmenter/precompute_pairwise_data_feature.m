% @authors:     Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function precompute_pairwise_data_feature(seg_obj)
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

    % further adjust gPb boundaries by looking at superpixels
    bndry = Segmenter.adjust_boundaries_sp(bndry, seg_obj.sp_data.sp_seg);


    % val can range [0, 255]
    val = intens_pixel_diff_mex(double(bndry), uint32(bndry_pairs(:,1)), ...
                                               uint32(bndry_pairs(:,2)));
    % intens_pixel_diff_mex is equivalent to:
    % gPb_dbl = double(gPb);
    % val = abs(gPb_dbl(ids(:,1)) - gPb_dbl(ids(:,2)));

    % setting median value for each edglet
    [feat, the_rest, ~, sel] = gen_sp_feats(seg_obj, val);
    if  strncmp(seg_obj.segm_params.boundaries_method,'SketchTokens',11)
        load(fullfile(seg_obj.filepath_params.trained_models_dirpath, ...
            'pair_trees_fix_high.mat'));
    elseif strncmp(seg_obj.segm_params.boundaries_method,'Gb',2)
        load(fullfile(seg_obj.filepath_params.trained_models_dirpath, ...
            'pair_trees_fix_high_gb.mat'));
    elseif strncmp(seg_obj.segm_params.boundaries_method,'StructEdges',11)
        load(fullfile(seg_obj.filepath_params.trained_models_dirpath, ...
            'pair_trees_high_StructEdges.mat'));
    else
        error(['Unknown boundary method ' ...
               seg_obj.segm_params.boundaries_method '!']);
    end
    
    accum_edge(sel) = eval_tree_lad(feat', trees, scaling_type, ...
                                    scaling, f0, rho);
    accum_edge(accum_edge < 0) = 0;
    % Somehow, the GB learned edges are of very low strength
    if strcmp(seg_obj.segm_params.boundaries_method,'Gb')
        accum_edge = accum_edge / 0.765;
    end
    % Instead of median use eval_tree_lad
    accum_edge(sel) = accum_edge(sel) * 255;
    accum_edge(~sel) = the_rest(~sel);
    seg_obj.edge_vals = accum_edge(edgelet_ids);
    %draw_pairwise_sp(seg_obj.sp_data.sp_seg, bndry_pairs, edgelet_ids, accum_edge')
    time_util(seg_obj, 'precompute_pairwise_time', t_pair_precomp, 0, 0);
end
