% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [edge_vals] = ...
        get_pairwise_capacities(edge_vals, graph_pairwise_sigma, ...
                                graph_pairwise_contr_weight, ...
                                graph_pairwise_potts_weight)
    SIGMA = 0.5 / (graph_pairwise_sigma ^ 2);

    % convert boundaries difference into pairwise capacities (i.e. should 
    % be exp inverse to make big value small and vice versa)
    % SIGMA: decides falloff of the exponent. The smaller the value the 
    %   smoother the falloff (a is inverse square of graph_pairwise_sigma).
    % graph_pairwise_contr_weight: is the value given when edge_val=0
    % POTTS_WEIGHT: is just an offset for the final values
    new_val = (graph_pairwise_contr_weight .* ...
               exp(-(edge_vals)*SIGMA)) + ...
               graph_pairwise_potts_weight + 0.007;
    duh = hist(new_val);
    if duh(2) > duh(1)
        SIGMA = SIGMA + 0.07;
        new_val = (graph_pairwise_contr_weight .* ...
                   exp(-(edge_vals)*SIGMA)) + ...
                   graph_pairwise_potts_weight + 0.007;
    end
    edge_vals = new_val;
end