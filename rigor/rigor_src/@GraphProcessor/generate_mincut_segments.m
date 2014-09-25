function [curr_segments] = generate_mincut_segments(gp_obj)
% Top level function which performs parametric min-cut, once the pairwise 
% and unary capacities have been computed. The main job of this function is
% to call the right function according to which method needs to be used for
% parametric min-cut, and then collate the results once that function 
% returns. gp_obj is a GraphProcessor object
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    t_pmc_full = tic;
    
    fprintf('\tComputing min st cut for all unaries ... ');
    
    pmc_maxflow_method = gp_obj.segm_params.pmc_maxflow_method;
    
    if ~isempty(strfind(pmc_maxflow_method, 'nodynamic')) || ...
       ~isempty(strfind(pmc_maxflow_method, 'kohli')) || ...
       ~isempty(strfind(pmc_maxflow_method, 'multiseed'))
   
        num_graph_types = length(gp_obj.graph_sets_per_method);
        
        start_ind = cumsum([1 gp_obj.graph_sets_per_method]);
        sols_to_unary_mapping = repmat({[]}, 1, num_graph_types);
        
        graphcut_params = [];
        if ~isempty(gp_obj.graph_sub_methods_cut_param)
            graphcut_params = gp_obj.graph_sub_methods_cut_param;
        end

        t_pmc_total_all = tic;
        
        [partitions, lambdas, seed_mapping, mincut_vals, t_pmc_all, ...
         cut_info] = gp_obj.multiseed_param_min_st_cut(...
                        gp_obj.segm_params.pmc_maxflow_method, ...
                        start_ind(1:end-1), graphcut_params);
        
        t_pmc_total_all = toc(t_pmc_total_all);
        t_pmc_total_all = repmat(t_pmc_total_all / num_graph_types, ...
                                 num_graph_types, 1);
        
        segs_meta_info.lambdas = lambdas;
        segs_meta_info.mincut_vals = mincut_vals;
        segs_meta_info.extra_cut_info = cut_info;
        
        curr_segments.cut_segs = partitions;
        curr_segments.segs_meta_info.sols_to_unary_mapping = seed_mapping;
    
    elseif strcmp(pmc_maxflow_method, 'hochbaum')
        num_graphs = size(gp_obj.graph_unaries_all.lambda_s,2);

        t_pmc_all = nan(num_graphs, 1);
        t_pmc_total_all = nan(num_graphs, 1);
        num_segs = nan(num_graphs, 1);
        
        segs_meta_info = repmat(struct, 1, num_graphs);
        partitions = repmat({[]}, 1, num_graphs);

        pmc_parallel_loop = tic;
        parfor(graph_idx = 1:num_graphs, 8)
%         for graph_idx = 1:num_graphs
            t_pmc_total = tic;

            [part, lambdas, mincut_vals, t_pmc] = ...
                gp_obj.parametric_min_st_cut(graph_idx);

            partitions{graph_idx} = ~part;
            segs_meta_info(graph_idx).lambdas = lambdas;
            segs_meta_info(graph_idx).mincut_vals = mincut_vals;
            segs_meta_info(graph_idx).extra_cut_info = [];

            num_segs(graph_idx) = size(part,2);
            t_pmc_all(graph_idx) = t_pmc;
            t_pmc_total_all(graph_idx) = toc(t_pmc_total);
        end
        pmc_parallel_loop = toc(pmc_parallel_loop);
        
        submethod_inds = ...
            duplicateElems(1:length(gp_obj.graph_sets_per_method), ...
                           gp_obj.graph_sets_per_method);
        parallel_fact = pmc_parallel_loop / sum(t_pmc_total_all);
        t_pmc_all = accumarray(submethod_inds(:), t_pmc_all) .* parallel_fact;
        t_pmc_total_all = accumarray(submethod_inds(:), t_pmc_total_all) ...
                          .* parallel_fact;
        
        curr_cut_segs = cell2mat(partitions);
        
        curr_segments.cut_segs = curr_cut_segs(1:end-2,:);
        curr_segments.segs_meta_info.sols_to_unary_mapping = ...
                        duplicateElems(1:length(num_segs), num_segs);
    else
        error('GraphProcessor:generate_mincut_segments', ...
              'Invalid min cut method: %s', pmc_maxflow_method);
    end
    
    % if debug, print segments overlayed over the image
    graph_num = length(gp_obj.seg_obj.num_segs.init_segs) + 1;
    diagnostic_methods('gen_masks_overlay', gp_obj.seg_obj, ...
                       curr_segments, ...
                       fullfile(sprintf('cuts%02d',graph_num), ...
                                '%03d_%04d.png'));
    
    total_segs = size(curr_segments.cut_segs,2);
    
    gp_obj.seg_obj.num_segs.init_segs = ...
        [gp_obj.seg_obj.num_segs.init_segs, total_segs];
    
    curr_segments.segs_meta_info.lambdas = [segs_meta_info.lambdas];
    curr_segments.segs_meta_info.mincut_vals = [segs_meta_info.mincut_vals];
    curr_segments.segs_meta_info.extra_cut_info = [segs_meta_info.extra_cut_info];
    curr_segments.segs_meta_info.seg_mapping_final_to_orig = 1:total_segs;
    
    time_util(gp_obj.seg_obj, 'pmc_time', t_pmc_full, 1, 1);
    fprintf('\t\t produced %d segments\n', ...
            gp_obj.seg_obj.num_segs.init_segs(end));
    
    gp_obj.seg_obj.timings.pmc_parallel_cut_time = ...
        [gp_obj.seg_obj.timings.pmc_parallel_cut_time, t_pmc_all'];
    gp_obj.seg_obj.timings.pmc_parallel_overhead_time = ...
        [gp_obj.seg_obj.timings.pmc_parallel_overhead_time, ...
         t_pmc_total_all' - t_pmc_all'];
end
