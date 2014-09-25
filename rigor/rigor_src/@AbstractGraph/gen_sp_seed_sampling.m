% @authors:     Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [seed_sets] = gen_sp_seed_sampling(graph_seed_params, seg_obj)
    NUM_SEEDS_PER_ROUND = graph_seed_params{1};
    NUM_STRATA = graph_seed_params{2};
    ranker_file = fullfile(seg_obj.filepath_params.data_save_dirpath, graph_seed_params{3});
    sigma = graph_seed_params{4};
    diagnostics = 0;
    
    pre_edge_vals = seg_obj.edge_vals;
    
    edge_vals = AbstractGraph.get_pairwise_capacities(pre_edge_vals, sigma, 1, 1e-3);
    
    accum_pre_vals = accumarray(seg_obj.sp_data.edgelet_ids, pre_edge_vals);
    accum_vals = accumarray(seg_obj.sp_data.edgelet_ids, edge_vals);
    
    edgelet_sp = seg_obj.sp_data.edgelet_sp;
    num_spx = seg_obj.sp_data.num_spx;
    
    pre_pairwise_graph = sparse(edgelet_sp(:,1), edgelet_sp(:,2), accum_pre_vals, num_spx, num_spx);
    pre_pairwise_graph = pre_pairwise_graph + pre_pairwise_graph';
    
    pairwise_graph = sparse(edgelet_sp(:,1), edgelet_sp(:,2), accum_vals, num_spx, num_spx);
    pairwise_graph = pairwise_graph + pairwise_graph';
    
    % Compute superpixel potentials for initialization
    s_feat = compute_all_relevant_features(seg_obj.sp_data.sp_seg, pre_pairwise_graph);
    
    % Load the ranker
    load(ranker_file);
    if ~strncmp(ranker_name, 'classregtree_fuxin',16)
        disp('Unsupported ranker.');
    end
    switch (ranker_name)
        case 'classregtree_fuxin_l2boost'
            val = eval_tree(s_feat, trees, scaling_type, scaling);
        case 'classregtree_fuxin_ladboost'
            val = eval_tree_lad(s_feat, trees, scaling_type, scaling, f0, rho);
    end
    
    iter = 1;
    real_masks = false(0,0);
    all_vals = [];
    all_seeds = [];
    energy = [];
    this_round = 1;
    num_partitions = floor(NUM_SEEDS_PER_ROUND / NUM_STRATA);
    seeds_per_part = ceil(NUM_SEEDS_PER_ROUND / num_partitions);
    val_partitions = generate_val_partition(pairwise_graph, val - min(val), num_partitions);
    if diagnostics
        n_rows = floor(sqrt(num_partitions));
        n_cols = ceil(num_partitions / n_rows);
        for i=1:length(val_partitions)
            subplot(n_rows,n_cols,i), imshow(ismember(seg_obj.sp_data.sp_seg, val_partitions{i}));
        end
    end
    
    % Diagnostics
    if diagnostics
       figure,display_seed_strength(seg_obj.sp_data.sp_seg, val);
    end
    
    % sample some seeds 
    masks = false(0,0);
    t = tic();
%        seeds = slice_sampler(val - min(val), NUM_SEEDS_PER_ROUND, true);
    seeds = zeros(seeds_per_part, num_partitions);
    for i=1:num_partitions
        seeds(:,i) = systematic_sampler(val(val_partitions{i}) - min(val), seeds_per_part);
        seeds(:,i) = val_partitions{i}(seeds(:,i));
    end
    % Resample if we sampled too many
    if num_partitions * seeds_per_part ~= NUM_SEEDS_PER_ROUND
        seeds = seeds(randperm(num_partitions * seeds_per_part, NUM_SEEDS_PER_ROUND));
    else
        seeds = seeds(:);
    end
    all_seeds = [all_seeds;seeds];
    
    seed_sets = false(num_spx, length(all_seeds));
    seed_indxs = sub2ind(size(seed_sets), all_seeds', 1:length(all_seeds));
    seed_sets(seed_indxs) = true;
end

function val = eval_tree(features, trees, scaling_type, scaling)
    new_feats = scale_data(features', scaling_type, scaling)';
    val = zeros(size(features,2));
    for i=1:length(trees)
        val = val + trees{i}.eval(double(new_feats));
    end
end

function val = eval_tree_lad(features, trees, scaling_type, scaling, f0, rho)
    new_feats = scale_data(features', scaling_type, scaling)';
    val = ones(size(features,1),1) * f0;
    for i=1:length(trees)
        val = val + rho(i) * trees{i}.eval(double(new_feats));
    end
end

function display_seed_strength(sp_seg, strength,I)
    sp2 = zeros(size(sp_seg));
    for i=1:numel(strength)
        sp2(sp_seg==i) = strength(i);
    end
%    subplot(1,2,1),imshow(I)
%    subplot(1,2,2),imagesc(sp2)
    if exist('I','var') && ~isempty(I)
        new_img = immerge(double(I)./255, cat(3,zeros(size(I,1),size(I,2),2), ones(size(I,1),size(I,2),1)), 0.7 *( sp2 > 0));
        imshow(new_img)
    else
        imagesc(sp2);
    end
end