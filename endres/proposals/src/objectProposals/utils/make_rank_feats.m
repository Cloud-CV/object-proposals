function feats = make_rank_feats(input)


feats = input;
feats(:, [17 18]) = 1./(1+exp(-input(:, [17 18]))); % These are logistic predictions
feats = [feats, feats.^2, ones(size(feats,1), 1)];
