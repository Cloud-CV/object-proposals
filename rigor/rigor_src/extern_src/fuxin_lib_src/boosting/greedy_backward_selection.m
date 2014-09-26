function [best_err,delete_seq] = greedy_backward_selection(train_feats, qualities, val_feats, qualities_val, depth, max_iter)
    iter = 1;
    train_feats = double(train_feats);
    val_feats = double(val_feats);
    feat_names = 1:size(train_feats,2);
    while size(train_feats,2) > 1
        for i=1:size(train_feats,2)
            err(i,:) = ladboost(train_feats(:,[1:i-1 i+1:end]), ...
                qualities,val_feats(:,[1:i-1 i+1:end]), qualities_val,depth,max_iter);
        end
        [best_err(iter),to_delete] = min(min(err,[],2));
        best_err(iter)
        train_feats = train_feats(:,[1:to_delete-1 to_delete+1:end]);
        val_feats = val_feats(:,[1:to_delete-1 to_delete+1:end]);
        delete_seq(iter) = feat_names(to_delete)
        feat_names = feat_names([1:to_delete-1 to_delete+1:end]);
        iter = iter + 1;
        clear err;
    end
end
