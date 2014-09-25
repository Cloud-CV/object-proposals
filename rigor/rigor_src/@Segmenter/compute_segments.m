function compute_segments(seg_obj)
%COMPUTE_SEGMENTS this is the main workhorse function of Segmenter. It uses
% the precomputed boundaries, superpixels, seed locations, and parwise
% potentials to generate multiple foreground segments. It will perform
% these steps for each of the different graphs given by 
% seg_obj.segm_params.graph_methods:
% (1) Compute the unaries for each seed for a graph sub-method and the 
%     pairwise/edge potential (most parameters are in seg_obj.segm_params)
% (2) Parametric min-cut for each seed set for every graph sub-method
% (3) Filter the segments produced by min-cut
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    graph_methods = seg_obj.segm_params.graph_methods;
    
    % initialize the matrix which will store all the segments generated
    seg_obj.cut_segs = false(seg_obj.sp_data.num_spx,0);
    
    % iterate over all different graph methods (like uniform and color
    % graphs) specified by segm_params.graph_methods
    for graph_idx = 1:length(graph_methods)
        t_seg_all = tic;
        
        % initialize the current type Segmenter class (copying parameters
        % and preparing data-structures)
        graph_name = graph_methods{graph_idx};
        graph_obj = eval(sprintf('%s(seg_obj, %d);', graph_name, ...
                                                     graph_idx));
        
        % compute all the unary values for all seeds for each Graph
        % sub-method (stored in graph_obj.graph_unaries_all). Also compute
        % the final binary capacities between superpixel pairs (stored in
        % graph_obj.edge_vals)
        prepare_graphs(graph_obj);
        
        % GraphProcessor handles the parametric min-cut/max-flow 
        % (graph-cuts on Ising model) to produce binary segments
        % In the the constructor it prepares a data-structure for min-cut
        gp_obj = GraphProcessor(graph_obj, graph_idx);
        
        % function where GraphProcessor computes min-cut for all the graph
        % sub-methods
        [curr_segments] = generate_mincut_segments(gp_obj);
        
        % here the Segmenter filters the output min-cut segments produced 
        % by GraphProcessor
        [curr_segments] = filter_segments(seg_obj, gp_obj, graph_idx, ...
                                          curr_segments);
        
        seg_obj.num_segs.after_clustering_FINAL = ...
            [seg_obj.num_segs.after_clustering_FINAL, ...
             size(curr_segments.cut_segs,2)];
    
        fprintf('\tFinal number of segments: %d\n', ...
                seg_obj.num_segs.after_clustering_FINAL(end));
        
        seg_obj.cut_segs = [seg_obj.cut_segs, curr_segments.cut_segs];
        if isempty(curr_segments.cut_segs)
            curr_segments.segs_meta_info.sols_to_unary_mapping = [];
            curr_segments.segs_meta_info.lambdas = [];
            curr_segments.segs_meta_info.mincut_vals = [];
            curr_segments.segs_meta_info.extra_cut_info = [];
            curr_segments.segs_meta_info.seg_mapping_final_to_orig = [];
            curr_segments.segs_meta_info.energies = [];
        end
        seg_obj.meta_cut_segs_info = ...
            [seg_obj.meta_cut_segs_info, curr_segments.segs_meta_info];
    
        seg_obj.timings.total_computing_segs_time = ...
            [seg_obj.timings.total_computing_segs_time, toc(t_seg_all)];
    end
    
    % converting superpixel segments into full image segments
    seg_obj.cut_segs = convert_masks(uint16(seg_obj.sp_data.sp_seg), ...
                                     seg_obj.cut_segs);
    
    seg_obj.timings.total_seg_time = toc(seg_obj.timings.total_seg_time);
    fprintf('Total segmentation time %.2fs\n', ...
            seg_obj.timings.total_seg_time);
end
