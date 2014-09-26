function [err,tree,f0,rho] = ladboost(train_feats, train_y, val_feats, val_y, depth, max_iter, alpha)
% Run L2-Boosting and test parameters
    DefaultVal('max_iter',100);
    err_increase = 1;
    pred_train = zeros(numel(train_y),1);
    pred_val = zeros(numel(val_y),1);
    f0 = median(train_y);
    residual = train_y - f0;
    pred_train = ones(numel(train_y),1) * f0;
    pred_val = ones(numel(val_y),1) * f0;
    for i=1:max_iter
        tree{i} = classregtree_fuxin(train_feats, sign(residual), 'minleaf',numel(train_y) / 2^(depth-1));
        if exist('alpha','var')
            tree{i} = tree{i}.prune('alpha',alpha);
        end
        val = tree{i}.eval(train_feats);
        rho(i) = weightedMedian( residual ./ val, abs(val));
        pred_train = pred_train + rho(i) * val;
        residual = train_y - pred_train;
        pred_val = pred_val + rho(i) * tree{i}.eval(val_feats);
        residual_val = val_y - pred_val;
        err(i) = mean(abs(residual_val))
        if i > 1 && err(i) >= err(i-1)
            err_increase = err_increase + 1;
        else
            err_increase = 0;
        end
        if err_increase > 3
            break;
        end
    end
    [a,b] = min(err(1:i));
    tree = tree(1:b);
    rho = rho(1:b);
end