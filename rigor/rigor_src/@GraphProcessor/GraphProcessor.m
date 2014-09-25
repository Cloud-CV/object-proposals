classdef GraphProcessor < handle
%GRAPHPROCESSOR is a class used by Segmenter to construct graphs and
% perform parametric min-cut on it to produce segments.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    properties
        seg_obj
        segm_params
        
        pairwise_edges
        pairwise_vals
        graph_unaries_all
        graph_sets_per_method
        graph_sub_methods_cut_param
        
        graph_sol_upper_bp
        
        n_nodes
        fg_node_id
        bg_node_id
        
        pairwise_graph
    end
    
    methods (Access = public)
        function obj = GraphProcessor(graph_obj, segm_index)
            obj.seg_obj = graph_obj.seg_obj;
            obj.segm_params = graph_obj.seg_obj.segm_params;
            
            obj.pairwise_edges = graph_obj.seg_obj.sp_data.edgelet_sp;
            obj.pairwise_vals = graph_obj.edge_vals;
            obj.graph_unaries_all = graph_obj.graph_unaries_all;
            obj.graph_sets_per_method = graph_obj.graph_sets_per_method;
            obj.graph_sub_methods_cut_param = ...
                graph_obj.graph_sub_methods_cut_param;
            
            obj.n_nodes = graph_obj.seg_obj.sp_data.num_spx;
            obj.fg_node_id = graph_obj.fg_node_id;
            obj.bg_node_id = graph_obj.bg_node_id;
            
            obj.graph_sol_upper_bp = ...
                obj.seg_obj.segm_params.graph_sol_upper_bp(segm_index);
            
            % creates a sparse matrix of size (N+2)x(N+2) where N is the
            % number of superpixels, where each position gives the edge
            % cost between a pair of superpixels (note that this would not
            % put the unary costs in the matrix)
            prepare_graphs_for_mincut(obj);
        end
        
        [curr_segments] = generate_mincut_segments(obj);
    end
    
    methods (Access = private)
        function prepare_graphs_for_mincut(obj)
            obj.pairwise_graph = ...
                GraphProcessor.add_dual_edges([], obj.pairwise_edges, ...
                                              obj.pairwise_vals, ...
                                              obj.n_nodes + 2);
        end
        
        [cuts, lambdas, mincut_vals, t_pmc] = ...
            parametric_min_st_cut(obj, graph_idx);
        
        [part, lambdas, seed_mapping, mincut_vals, t_pmc, cut_info] = ...
            multiseed_param_min_st_cut(obj, method_str, graph_idxs, ...
                                       graphcut_params);
        
        [cuts, lambdas, t_pmc] = ...
            pseudoflow_min_cut_param(obj, prob_graph, lambda_edges, ...
                                     lambda_weights, lambda_offsets);
        
        [cuts, lambdas, mincut_vals, t_pmc] = ...
            kolmogorov_min_cut_param(obj, prob_graph, lambda_edges, ...
                                     lambda_weights, lambda_offsets);
        
        [nonlambda_s, nonlambda_t, lambda_s, lambda_t, lambda_range, ...
          pairwise_edges, DISC_FACTOR, BIG_VALUE] = ...
            preprocess_graphs(gp_obj, nonlambda_s, nonlambda_t, ...
                              lambda_s, lambda_t);
    end
    
    methods (Access = private, Static)
        [lambda_range] = generate_param_lambdas(l, u, DISC_FACTOR, ...
                                                pmc_num_lambdas, ...
                                                overrride_lambdas);
        
        function graph = add_dual_edges(graph, node_ids, edge_vals, ...
                                        n_nodes)
            if ~isempty(graph)
                n_nodes = size(graph,1);
            end
            
            % this function is like add_edges(), but it adds edges in both
            % directions (bidirectional edges)
            new_graph = sparse(node_ids(:,1), node_ids(:,2), ...
                               edge_vals, n_nodes, n_nodes);
            new_graph = new_graph + new_graph';
            
            if isempty(graph)
                graph = new_graph;
            else
                graph = graph + new_graph;
            end
        end
    end
end
