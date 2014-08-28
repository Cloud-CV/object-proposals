function [ranking pw_region_overlaps] = rankProposals(image_data, final_regions, ranking_feats, w)


pw_region_overlaps = get_region_overlaps(final_regions, image_data.occ.bndinfo_all{1}, 0.5);
feats = make_rank_feats(ranking_feats);%, feats_all.^2, ones(size(feats_all,1),1)];

[ranking, score, dk, unary] = greedy_max_score(feats', pw_region_overlaps, w);

