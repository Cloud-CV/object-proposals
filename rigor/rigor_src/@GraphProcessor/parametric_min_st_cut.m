% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [cuts, lambdas, mincut_vals, t_pmc] = ...
        parametric_min_st_cut(gp_obj, graph_idx)
    
    nonlambda_s = gp_obj.graph_unaries_all.nonlambda_s(:,graph_idx);
    nonlambda_t = gp_obj.graph_unaries_all.nonlambda_t(:,graph_idx);
    lambda_s = gp_obj.graph_unaries_all.lambda_s(:,graph_idx);
    lambda_t = gp_obj.graph_unaries_all.lambda_t(:,graph_idx);
    
    t_pmc = NaN;
    mincut_vals = NaN;
    
    % adjust graph (like thresholding values and data conversion) before
    % creating the final data structure used by graph cuts
    [nonlambda_s, nonlambda_t, lambda_s, lambda_t, lambda_range, ...
        pairwise_edges] = preprocess_graphs(gp_obj, nonlambda_s, ...
                                            nonlambda_t, lambda_s, ...
                                            lambda_t);
    
    % make the final data structure to be used by the respective graph cut
    % method
    [graph_constr_vals] = get_graph_constr(gp_obj.fg_node_id, ...
                                           gp_obj.bg_node_id, ...
                                           nonlambda_s, nonlambda_t, ...
                                           lambda_s, lambda_t, ...
                                           lambda_range, pairwise_edges);
    
    if strcmpi(gp_obj.segm_params.pmc_maxflow_method, 'hochbaum')
        [cuts, lambdas, t_pmc] = ...
            pseudoflow_min_cut_param(gp_obj, graph_constr_vals);
        
    elseif strcmp(gp_obj.segm_params.pmc_maxflow_method, 'kolmogorov')
        [cuts, lambdas, mincut_vals, t_pmc] = ...
            kolmogorov_min_cut_param(gp_obj, graph_constr_vals);
    else
        error(['''%s'' algorithm is not available, only kolmogorov ' ...
               'and hochbaum available'], ...
               gp_obj.segm_params.pmc_maxflow_method);
    end

    % adjust the vector of mincut values incase none were returned
    if all(isnan(mincut_vals))
        mincut_vals = repmat(NaN, 1, size(cuts,2));
    end
end

function [graph_constr_vals] = get_graph_constr(s, t, nonlambda_s, ...
                                                nonlambda_t, lambda_s, ...
                                                lambda_t, lambda_range, ...
                                                pairwise_edges)
    src_lambda_edges_rows = [];
    sink_lambda_edges_rows = [];
    src_edges_rows = [];
    sink_edges_rows = [];
    
    %%%%%%%%% Make matrix with lambda weights from/to src/sink %%%%%%%%%
    
    % find parametric edges which come out of the src node
    if any(lambda_s)
        % sort lambda in ascending order
        src_range = sort(lambda_range, 2, 'ascend');
        s_lambda = lambda_s ~= 0;
        % get the rx1 src weights
        src_lambda_weights = lambda_s(s_lambda);
        % multiply src weights with different lambdas giving rxm matrix
        src_lambda_weights = bsxfun(@times, src_lambda_weights, src_range);
        % add the non-parametric capacity with lambda multiplied weight
%         src_lambda_weights = bsxfun(@plus, src_lambda_weights, ...
%                                            nonlambda_s(s_lambda));
        % augment matrix with the edge indices in the first two columns
        src_lambda_edges_rows = [[repmat(s, nnz(s_lambda), 1), ...
                                  find(s_lambda)], ...
                                 src_lambda_weights];

    end

    % find parametric edges which go into the sink node
    if any(lambda_t)
        % reverse lambda for sink nodes
        sink_range = sort(lambda_range, 2, 'descend');
        t_lambda = lambda_t ~= 0;
        % get the kx1 sink weights
        sink_lambda_weights = lambda_t(t_lambda);
        % multiply sink weights with different lambdas giving kxm matrix
        sink_lambda_weights = bsxfun(@times, sink_lambda_weights, sink_range);
        % add the non-parametric capacity with lambda multiplied weight
%         sink_lambda_weights = bsxfun(@plus, sink_lambda_weights, ...
%                                             nonlambda_t(t_lambda));
        % augment matrix with the edge indices in the first two columns
        sink_lambda_edges_rows = [[find(t_lambda), ...
                                   repmat(t, nnz(t_lambda), 1)], ...
                                  sink_lambda_weights];
    end
    
    
    %%%%% Make matrix with non-parametric weights from/to src/sink %%%%%
    
    % find the non-parametric edges coming out of sink
    src_edges = find(nonlambda_s);
    if ~isempty(src_edges)
        % first two columns are edge indices, and rest of columns are the
        % replicated with the non-parametric weights (capacities) from src
        nonlambda_s = nonlambda_s(src_edges);
        src_edges_rows = [repmat(s, length(src_edges), 1), ...
                          src_edges, ...
                          repmat(nonlambda_s, 1,length(lambda_range))];
    end
    
    % find the non-parametric edges coming into the sink
    sink_edges = find(nonlambda_t);
    if(~isempty(sink_edges))
        % first two columns are edge indices, and rest of columns are the
        % replicated with the non-parametric weights (capacities) to sink
        nonlambda_t = nonlambda_t(sink_edges);
        sink_edges_rows = [sink_edges, ...
                           repmat(t, length(sink_edges), 1), ...
                           repmat(nonlambda_t, 1,length(lambda_range))];
    end

    
    %%%%% Make the complete matrix with all unary weights (parametric and
    %%%%% non-parametric). First two columns are the edge indices and the
    %%%%% remaining columns give the capacities for a different lambda. The
    %%%%% data structure is as follows
    % a < source > < to-node > < capacity1 > < capacity2 > .. < capacityk >
    % a < from-node > < sink > < capacity1 > < capacity2 > .. < capacityk >
    unary_parametric_edges = [src_lambda_edges_rows; ...
                              sink_lambda_edges_rows; ...
                              src_edges_rows; ...
                              sink_edges_rows];
    %unary_parametric_edges = round(unary_parametric_edges);
    
    n_params = size(lambda_range,2);
    
    % all these methods require to specify backward forward edges
    pairwise_edges = [pairwise_edges; pairwise_edges(:,[2 1 3])];
    
    n_nodes = t;
    n_arcs = size(unary_parametric_edges,1) + size(pairwise_edges,1);

    graph_constr_vals.n_nodes = n_nodes;
    graph_constr_vals.n_arcs = n_arcs;
    graph_constr_vals.n_params = n_params;
    graph_constr_vals.lambda_range = lambda_range;
    graph_constr_vals.s = s;
    graph_constr_vals.t = t;
    graph_constr_vals.pairwise_edges = pairwise_edges;
    graph_constr_vals.unary_parametric_edges = unary_parametric_edges;
end
