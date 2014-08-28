function w = trainBoundaryClassifier(x, y)
% w = trainBoundaryClassifier(x, y)

DO_PER_ITER = 0;

% L1 logistic regression
if ~DO_PER_ITER
    alphas = [0.001 0.005 0.01 0.025 0.05 0.1 0.25 0.5 0.75 1 1.5 2 2.5 5 7.5 10];
    search_for_alpha = false;
    testind = 1:round(numel(y))/4;
    retrain_with_all = true;
    [w, alpha, ll_ave] = logregL1Train(x, y, alphas, search_for_alpha, testind, retrain_with_all);
end    
    
% the scheme below was shown in validation to perform similarly to that above while being slightly more complicated
if DO_PER_ITER 
    for k = 1:4
        % get indices 
        if k < 4
            ind = x(:, k)>0 & x(:, k+1)==0;
        else
            ind = x(:, k)>0;
        end

        alphas = [0.001 0.005 0.01 0.025 0.05 0.1 0.25 0.5 0.75 1 1.5 2 2.5 5 7.5 10];
        search_for_alpha = false;
        testind = 1:round(sum(ind))/4;
        retrain_with_all = true;
        [w(:, k), alpha(k), ll_ave(k)] = logregL1Train(x(ind, :), y(ind), ...
            alphas, search_for_alpha, testind, retrain_with_all);    
    end
end