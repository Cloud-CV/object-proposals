function [err,tree] = l2boost(train_feats, train_y, val_feats, val_y, depth, max_iter, alpha)
% Run L2-Boosting and test parameters
    DefaultVal('max_iter',100);
    residual = train_y;
    err_increase = 1;
    pred_train = zeros(numel(train_y),1);
    pred_val = zeros(numel(val_y),1);
    for i=1:max_iter
        tree{i} = classregtree_fuxin(train_feats, residual, 'minleaf',numel(train_y) / 2^(depth-1));
        if exist('alpha','var')
            tree{i} = tree{i}.prune('alpha',alpha);
        end
        pred_train = pred_train + tree{i}.eval(train_feats);
        residual = train_y - pred_train;
        pred_val = pred_val + tree{i}.eval(val_feats);
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
end