function [lambda_range] = generate_param_lambdas(l, u, DISC_FACTOR, ...
                                                 pmc_num_lambdas, ...
                                                 overrride_lambdas)
% computes the list of lambda parameters used for parametric min-cut
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    original_l = 0.001;
    original_u = 20;
    N_LAMBDAS = 20;
    
    if exist('pmc_num_lambdas','var') == 1 && ~isempty(pmc_num_lambdas)
        N_LAMBDAS = pmc_num_lambdas;
    end

    if l == -1
        l = original_l;
    end

    if u == -1
        u = original_u;
    end

    assert(l >= original_l);
    
    if exist('overrride_lambdas','var') == 1 && ~isempty(overrride_lambdas)
        % in case user has provided exact lambdas to work with
        lambda_range = overrride_lambdas;
    else
        lambda_range = logspace(log10(l), log10(u), N_LAMBDAS);
        %pars.lambda_range =  [linspace(l, u, N_LAMBDAS)];
        lambda_range(lambda_range > (u+eps)) = [];
        lambda_range(l > lambda_range) = [];
        lambda_range = [0 lambda_range];
    end
end
