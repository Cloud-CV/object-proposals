% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [cuts, lambdas, mincut_vals, t_pmc] = ...
            kolmogorov_min_cut_param(gp_obj, graph_constr_vals)
    
    pairwise_edges = gp_obj.pairwise_edges;
    pairwise_vals = gp_obj.pairwise_vals * 1000;

    unary_capacities = zeros(gp_obj.n_nodes, 2, 'double');

    s_unaries = graph_constr_vals.unary_parametric_edges(:,1) == graph_constr_vals.s;
    s_unary_nodes = graph_constr_vals.unary_parametric_edges(s_unaries,2);
    t_unaries = graph_constr_vals.unary_parametric_edges(:,2) == graph_constr_vals.t;
    t_unary_nodes = graph_constr_vals.unary_parametric_edges(t_unaries,1);
% 
%             h = GCO_Create(n_nodes-2, 2);
%             GCO_SetNeighbors(h, pairwise_capacities);
%             
    t_pmc = 0;
    cuts = [];
    lambdas = [];
    mincut_vals = [];

    % iterate over all lambdas
    % The first one is 0, I don't know whether that's anything useful
    for idx = 1:length(graph_constr_vals.lambda_range)
        curr_lambda = graph_constr_vals.lambda_range(idx);

        s_vals = graph_constr_vals.unary_parametric_edges(s_unaries,idx+2);
        t_vals = graph_constr_vals.unary_parametric_edges(t_unaries,idx+2);
        unary_capacities(1:max(s_unary_nodes),1) = accumarray(s_unary_nodes,s_vals);
        unary_capacities(1:max(t_unary_nodes),2) = accumarray(t_unary_nodes,t_vals);

        t_curr = tic;
%         BIG_VALUE = 21475000;
%         unary_capacities(unary_capacities > BIG_VALUE) = BIG_VALUE;

        [lbl, max_flow_val] = ...
            mex_maxflow_int(unary_capacities, pairwise_vals, ...
                        pairwise_edges(:,[1 2]));
%                 GCO_SetDataCost(h, unary_capacities);
%                 
%                 GCO_Expansion(h);
%                 lbl = GCO_GetLabeling(h);
        t_pmc = t_pmc + toc(t_curr);

%                 lbl = ~logical(lbl - 1);
        lbl = logical([lbl; 0; 1]);
        if isempty(cuts)
            cuts = lbl;
            lambdas = curr_lambda;
            mincut_vals = max_flow_val;
        else
            if any(cuts(:,end) ~= lbl)
                cuts = [cuts, lbl];
                lambdas = [lambdas, curr_lambda];
                mincut_vals = [mincut_vals, max_flow_val];
            end
        end
        if(sum(lbl) == 0)
            break;
        end
%                 
%                 imagesc(reshape(lbl-1, [188 250]));
%                 pause;
    end

%             GCO_Delete(h);

    % incase first segmentation is all fg
    if ~isempty(cuts) && all(cuts(1:end-2,1))
        cuts(:,1) = [];
        lambdas(:,1) = [];
        mincut_vals(:,1) = [];
    end

    % incase last segmentation is all bg
    if ~isempty(cuts) && ~any(cuts(1:end-2,end))
        cuts(:,end) = [];
        lambdas(:,end) = [];
        mincut_vals(:,end) = [];
    end

%             hoch_pmc = load('temp');
%             diff_mat = zeros(size(cuts,2), size(hoch_pmc.cuts,2));
%             for idx = 1:size(cuts,2)
%                 for idx2 = 1:size(hoch_pmc.cuts,2)
%                     diff_mat(idx,idx2) = ...
%                         nnz(~cuts(:,idx) & ~hoch_pmc.cuts(:,idx2)) / ...
%                         nnz(~cuts(:,idx) | ~hoch_pmc.cuts(:,idx2));
%                 end
%             end
end

function energy = aux_compute_cut(lbl, unary_capacities, pairwise_vals,pairwise_edges)
    energy = sum(unary_capacities(lbl==0,2)) + sum(unary_capacities(lbl==1,1));
    % Edge
    boundary = ismember(pairwise_edges(:,1), find(lbl==0)) & ismember(pairwise_edges(:,2), find(lbl==1));
    boundary = boundary | (ismember(pairwise_edges(:,2), find(lbl==0)) & ismember(pairwise_edges(:,1), find(lbl==1)));
    energy = energy + sum(pairwise_vals(boundary));
end