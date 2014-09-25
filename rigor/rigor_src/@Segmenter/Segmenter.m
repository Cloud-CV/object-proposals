classdef Segmenter < handle
% Main class which has the responsibility of producing object proposals.
% This includes the responsibility of computing the unaries, pairwise
% values, generating graphs, producing segments using parametric min-cut,
% and then filtering segments
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    properties
        I
        filepath_params
        segm_params
        other_params
        include_params
        preload_data
        input_info

        bndry_data
        sp_data

        edge_vals
        
        precomputed_seeds
        seed_mapping_idx
        
        sp_frame_set
        
        cut_segs
        meta_cut_segs_info
        timings
        num_segs
    end
 
    methods (Access = public)
        function obj = Segmenter(I, segm_params, filepath_params, ...
                                 other_params, input_info)
            % store image, the parameters, and the filepaths
            obj.I = I;
            
            obj.filepath_params = filepath_params;
            obj.segm_params = segm_params;
            obj.other_params = other_params;
            
            obj.input_info = input_info;
            [obj.input_info.img_dir, obj.input_info.img_name] = ...
                fileparts(input_info.img_filepath);
            
            % initialize the Segmenter (include paths, init 
            % data-structures, preload data, start threads ...) depending
            % on the parameters used
            segmenter_init(obj);
        end

        precompute_im_data(obj);
        
        compute_segments(obj);

        function bndry_filepath = return_boundaries_filepath(obj)
            [~, top_lvl_data_dir] = fileparts(obj.input_info.img_dir);
            bndry_postfix = upper(obj.segm_params.boundaries_method);

            bndry_filepath = ...
                fullfile(obj.filepath_params.boundaries_parent_dirpath, ...
                         obj.segm_params.boundaries_method, ...
                         top_lvl_data_dir, ...
                         sprintf('%s_%s.mat', obj.input_info.img_name, ...
                                              bndry_postfix));
        end

        function save_filepath = return_seg_save_filepath(obj)
            [~, top_lvl_data_dir] = fileparts(obj.input_info.img_dir);

            save_filepath = ...
                fullfile(obj.filepath_params.seg_save_dirpath, ...
                         top_lvl_data_dir, ...
                         sprintf('%s.mat', obj.input_info.img_name));
        end

        function scores_filepath = return_scores_filepath(obj)
            [~, top_lvl_data_dir] = fileparts(obj.input_info.img_dir);

            scores_filepath = ...
                fullfile(obj.filepath_params.scores_dirpath, ...
                         top_lvl_data_dir, ...
                         sprintf('%s_scores.mat', obj.input_info.img_name));
        end
        
        function clear_data(obj)
            obj.I = [];
            obj.preload_data = [];
            obj.bndry_data = [];
            obj.sp_data = [];
            obj.edge_vals = [];
            obj.precomputed_seeds = [];
            obj.seed_mapping_idx = [];
            obj.sp_frame_set = [];
            obj.cut_segs = [];
        end
    end
  
    methods (Access = private)
        segmenter_init(obj);
        
        precompute_pairwise_data(obj);
        precompute_pairwise_data_feature(obj);
        
        precompute_unary_data(obj);
        
        [curr_segments] = filter_segments(obj, gp_obj, graph_idx, ...
                                          curr_segments);
    end
  
    methods (Static)
        [sp_data, t_sp] = compute_superpixels(I, bndry_fat, segm_params);

        [bndry_pairs, edgelet_ids, edgelet_sp] = ...
            generate_sp_neighborhood(sp_seg);

        [bndry_thin] = adjust_boundaries_sp(bndry_thin, sp_seg);

        [bndry_thin, bndry_fat, extra_bndry_compute_time] = ...
            compute_boundaries(bndry_filepath, I, segm_params, ...
                               other_params, extra_params);
    end
end