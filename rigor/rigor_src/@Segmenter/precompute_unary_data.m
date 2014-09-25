function precompute_unary_data(seg_obj)
%PRECOMPUTE_UNARY_DATA - has the duty of generating all info that will be
% used for the computation of unary costs. The most important job out of
% this is to compute the seeds. One seed is just a collection of
% pixels/superpixels which will have infinite capacity edges to the fg/src
% segment. This essentially specifies what pixels/superpixels will
% necessarily be part of the object segment. Later on we will perform
% parametric min-cuts over all the seeds generated.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    % generate the frame set which is used in setting the bg costs
    [seg_obj.sp_frame_set] = generate_sp_img_frame(seg_obj.sp_data, ...
        'all', seg_obj.segm_params.bg_frame_width);

    % generate all the seeds (each seed would be used to generate one
    % parametric min-cut problem)
    [seg_obj.precomputed_seeds, seg_obj.seed_mapping_idx] = ...
        precompute_seeds(seg_obj);
end


function [set] = generate_sp_img_frame(sp_data, frame_kind, thickness)
 % frame_kind can be 'all', 'all_but_down', 'horiz', 'vert'.
 
    if nargin < 4
        thickness = 1;
    end

    sp_seg_im_sz = size(sp_data.sp_seg);

    % the frame pixel indices (returned in sorted order)
    pixel_set = frame_pixel_ids(sp_seg_im_sz(1), ...
                                sp_seg_im_sz(2), thickness, ...
                                frame_kind);
    
    % get the superpixels which fall onto the frame
    set = false(size(sp_data.sp_seg_szs));
    set(sp_data.sp_seg(pixel_set)) = true;
end


function [precomputed_seeds, seed_mapping_idx] = precompute_seeds(seg_obj)
% precomputing seeds has the advantage of not having to recompute seeds
% needlessly for different Segmenter methods using the same seed generation
% method. This function precomputes all seeds that are going to be used by
% the Segmenter

    precomputed_seeds = [];
    seeds_sha1 = {};
    sub_methods_mapping = seg_obj.segm_params.graph_sub_methods_seeds_idx;
    seed_mapping_idx = sub_methods_mapping;
    
    t_gen_seed = tic;
    
    % if user gave a single number for the # of seeds
    if ~iscell(seg_obj.segm_params.graph_seed_nums) && ...
        length(seg_obj.segm_params.graph_seed_nums) == 1
        num_seeds = seg_obj.segm_params.graph_seed_nums;
        seg_obj.segm_params.graph_seed_nums = ...
            [ceil(sqrt(num_seeds)) ceil(sqrt(num_seeds))];
    end
    % replicate seed_nums parameter if needed
    if ~iscell(seg_obj.segm_params.graph_seed_nums)
        seg_obj.segm_params.graph_seed_nums = ...
            repmat({seg_obj.segm_params.graph_seed_nums}, 1, ...
            length(unique(cell2mat(sub_methods_mapping))));
    end
    
    % precompute all the seeds
    for seed_idx = unique(cell2mat(sub_methods_mapping))
        seed_gen_method = ...
            seg_obj.segm_params.graph_seed_gen_method{seed_idx};
        seed_nums = seg_obj.segm_params.graph_seed_nums{seed_idx};
        seed_params = seg_obj.segm_params.graph_seed_params{seed_idx};
        seed_params = [seed_nums, seed_params];
        
        data_stream = [seed_gen_method, seed_params];
        seed_hash = num2str(sum(getByteStreamFromArray(data_stream)));
%         seed_hash = DataHash(data_stream, ...
%                              seg_obj.other_params.hash_params);
        
        % check if this seed type has not already been computed
        precomputed_seed_idx = find(strcmp(seed_hash, seeds_sha1));
        if isempty(precomputed_seed_idx)
            t_seed = tic;
            fprintf('Generating %s seeds ... ', seed_gen_method);
            
            % this seed hasn't been computed before (compute now)
            [seed_sets] = ...
                AbstractGraph.generate_graph_seeds(seed_gen_method, ...
                                                   seed_params, seg_obj);
            
            fprintf('%.2fs\n', toc(t_seed));
            precomputed_seeds(end+1).seed_sets = seed_sets;
            precomputed_seeds(end).seed_gen_method = seed_gen_method;
            precomputed_seeds(end).seed_parans = seed_params;
            seeds_sha1{end+1} = seed_hash;
            precomputed_seed_idx = length(precomputed_seeds);
            
            % if debug, print seed images
            diagnostic_methods('overlay_seeds', seg_obj, seed_sets, ...
                               sprintf('seeds_%02d.png', seed_idx));
        end
        
        % each Segmenter sub-method uses a certain seed generation method.
        % This mapping is stored in seed_mapping_idx. This needs to be
        % fixed since we are precomputing seeds where indexing might be
        % different (in precomputed_seeds)
        for idx = 1:length(seed_mapping_idx)
            seed_mapping_idx{idx}(sub_methods_mapping{idx} == seed_idx) = ...
                precomputed_seed_idx;
        end
    end
    
    time_util(seg_obj, 'precompute_seed_time', t_gen_seed, 0, 0);
end