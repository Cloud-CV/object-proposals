function [cuts, lambdas, t_pmc] = ...
        pseudoflow_min_cut_param(gp_obj, graph_constr_vals)
% replace very big values (including infinity) and discretize
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014
 
    t_pmc = tic;
    %[ids, lambdas] = hoch_pseudo_par(n_nodes, n_arcs, n_params, s, t, ...
    %                                 pairwise_edges, ...
    %                                 unary_parametric_edges);
    out = hoch_pseudo_par(graph_constr_vals.n_nodes, ...
                          graph_constr_vals.n_arcs, ...
                          graph_constr_vals.n_params, ...
                          graph_constr_vals.s, ...
                          graph_constr_vals.t, ...
                          graph_constr_vals.pairwise_edges, ...
                          graph_constr_vals.unary_parametric_edges);
    t_pmc = toc(t_pmc);

    % x gives the cut point for each variable
    x = out(:,2);
    % x(k) gives the cut point for variable ids(k)
    ids = out(:,1);
    
    % find the number of unique points
    un = unique(x);
    s_number = min(un);
    t_number = max(un);
    un(un==s_number) = [];
    un(un==t_number) = [];
    n_bp = length(un); % minus source and set
    
    % initialize all the solutions (each column corresponds to a lambda)
    cuts = true(graph_constr_vals.n_nodes, n_bp);
    cuts(graph_constr_vals.s,:) = false;

    if isempty(un)
        cuts = [];
        lambdas = [];
        return;
    end

    % set the solution according to the cut points
    cuts(ids(x==un(1)),:) = 0;
    for i = 2:n_bp
        cuts(ids(x==un(i)),i:end) = 0;
    end

    % we only want before-extremal values (the all-but-sink solution isn't
    % interesting)
    if all(cuts(1:end-1,end) == 0)
        cuts(:,end) = [];
    end

    lambda_ids = un-1;
    if lambda_ids(1) == 0
        lambda_ids(1) = [];
        initial_lambda = 0; %pars.lambda_range(lambda_ids(1))-eps;
    else
        initial_lambda = [];
    end
    lambdas = [graph_constr_vals.lambda_range(sort(lambda_ids, 'ascend')) initial_lambda];
    if length(lambdas) > size(cuts,2) % hack
        lambdas(end) = [];
    end
    
%     save('temp', 'pairwise_edges', 'unary_parametric_edges', 'lambdas', 'cuts');
end