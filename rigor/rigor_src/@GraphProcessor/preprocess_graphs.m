% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [nonlambda_s, nonlambda_t, lambda_s, lambda_t, lambda_range, ...
          pairwise_edges, DISC_FACTOR, BIG_VALUE ] = ...
            preprocess_graphs(gp_obj, nonlambda_s, nonlambda_t, ...
                              lambda_s, lambda_t)
    l = -1;
    u = gp_obj.graph_sol_upper_bp;
    
    DISC_FACTOR = 1000; % original is 1000
    
    % i don't think it can be bigger (beyond certain value goes crazy)
    BIG_VALUE = 21475000000;

    % get the range of lambda values to use
    pmc_num_lambdas = gp_obj.segm_params.pmc_num_lambdas;
    
    if ~exist('overrride_lambdas', 'var')
        overrride_lambdas = [];
    end
    
    lambda_range = ...
        GraphProcessor.generate_param_lambdas(l, u, DISC_FACTOR, ...
                                              pmc_num_lambdas, ...
                                              overrride_lambdas);
    
    % capping lambda weight and offsets (parametric capacities) to BIG_VALUE
    nonlambda_s = nonlambda_s * DISC_FACTOR;
    nonlambda_t = nonlambda_t * DISC_FACTOR;
    nonlambda_s(nonlambda_s > BIG_VALUE) = BIG_VALUE;
    nonlambda_t(nonlambda_t > BIG_VALUE) = BIG_VALUE;
    
    % capping non-lambda weights (non-parametric capacities) to BIG_VALUE
    lambda_s = lambda_s * DISC_FACTOR;
    lambda_t = lambda_t * DISC_FACTOR;
    lambda_s(lambda_s > BIG_VALUE) = BIG_VALUE;
    lambda_t(lambda_t > BIG_VALUE) = BIG_VALUE;
    
    pairwise_vals = gp_obj.pairwise_vals;
    pairwise_vals = pairwise_vals * DISC_FACTOR;
    pairwise_vals(pairwise_vals > BIG_VALUE) = BIG_VALUE;
    
    % a < from-node > < to-node > < capacity >
    pairwise_edges = [gp_obj.pairwise_edges pairwise_vals];
end