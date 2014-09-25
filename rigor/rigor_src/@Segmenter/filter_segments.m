function [curr_segments] = filter_segments(seg_obj, gp_obj, graph_idx, ...
                                           curr_segments)
%FILTER_SEGMENTS filters (discards) the segments based on different 
% criterion
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    % first check if we want to filter segments for the current graph
    if ~seg_obj.segm_params.graph_filter_segs{graph_idx}
        curr_segments.segs_meta_info.energies = [];
        return;
    end
        
    fprintf('\tFiltering segments\n');
    
    t_fltr = tic;
    % if no segments, return
    if isempty(curr_segments.cut_segs)
        return;
    end
    
    % separate each segment into its connected components. Also remove the
    % components (split segments) which are below min_npixels size
    [curr_segments] = ...
        separate_conn_comp(curr_segments, seg_obj, ...
                           seg_obj.segm_params.filter_min_seg_pixels);
    
    % just computes the pairwise edges cut value divided by the number of
    % pairwise edges cut (this is called the cut ratio)
    [curr_segments, t_energy] = compute_energies(curr_segments, ...
                                                 seg_obj, gp_obj);
    
    % filter segment which are above the filter_max_energy cut ratio
    [curr_segments] = filter_energies(curr_segments, seg_obj, ...
                                seg_obj.segm_params.filter_max_energy, ...
                                t_energy);
    
    % randomly throw away segments if more than filter_max_rand                  
    [curr_segments] = filter_rand(curr_segments, seg_obj, ...
                                  seg_obj.segm_params.filter_max_rand);
    
    % if multiple segments overlap, only keep the one with the lowest cut 
    % ratio
    [curr_segments] = remove_repeated_segments(curr_segments, seg_obj, ...
                                               gp_obj);
    
    % if user specified specified seeds, discard anything that doesn't
    % include the seed location itself (which can happen with color unaries
    % for instance)
    if strcmp(seg_obj.segm_params.graph_seed_gen_method,'gen_user_seeds')
        % find segments which cover all the seed superpixels (supposes that
        % there is only one seed in seed_sets)
        seed_cover = ...
            curr_segments.cut_segs(seg_obj.precomputed_seeds.seed_sets,:);
        conn = (sum(seed_cover,1) ...
            == sum(seg_obj.precomputed_seeds.seed_sets));
        [curr_segments] = cherry_pick_segments(curr_segments, conn);
    end

    seg_obj.timings.seg_filtering_time = ...
        [seg_obj.timings.seg_filtering_time, toc(t_fltr)];
end


function [curr_segments] = separate_conn_comp(curr_segments, seg_obj, ...
                                              min_npixels)
    fprintf('\t\tSeparating connected components ... ');
    
    t_conn = tic;
    
    if(nargin == 1)
        min_npixels = 25;
    end

    % separate each segment into its connected components by
    % finding connected components on the induced graph. Also remove the
    % components which are below min_npixels size
    [segms, num_comps] = sp_conncomp_mex(curr_segments.cut_segs, ...
                                         seg_obj.sp_data.edgelet_sp, ...
                                         seg_obj.sp_data.sp_seg_szs, ...
                                         min_npixels);
    
    % make the mapping which is an array of the length of the total 
    % number of new segments (each of which forms a connected
    % component) where each array location gives the index/id of
    % the original segment returned by the min-cut
    temp = duplicateElems(1:length(num_comps), num_comps);
    curr_segments.segs_meta_info.seg_mapping_final_to_orig = ...
        curr_segments.segs_meta_info.seg_mapping_final_to_orig(temp);

    curr_segments.cut_segs = segms;
    
    seg_obj.num_segs.after_splitting_conncomp = ...
        [seg_obj.num_segs.after_splitting_conncomp, sum(num_comps)];
    
    time_util(seg_obj, 'init_filter_time', t_conn, 1, 1);
end

function [curr_segments, t_energy] = compute_energies(curr_segments, ...
                                                      seg_obj, gp_obj)
    fprintf('\t\tComputing energies ... ');
    
    t_energy = tic;
    
    cut_ratio = zeros(1,size(curr_segments.cut_segs,2));
    for i = 1:length(cut_ratio)
        links_across = ...
            gp_obj.pairwise_graph(~curr_segments.cut_segs(:,i), ...
                                  curr_segments.cut_segs(:,i));
        cut = full(sum(links_across(:)));
        % cut ratio (minimizing it is called the sparsest cut problem)
        n_edges_across = nnz(links_across);
        cut_ratio(i) = cut / n_edges_across;
    end
    curr_segments.segs_meta_info.energies = cut_ratio;
    
    fprintf('%.2fs\n', toc(t_energy));
end

function [curr_segments] = filter_energies(curr_segments, seg_obj, ...
                                           max_energy, t_energy)
    fprintf('\t\tRemoving high energy solutions ... ');
    
    t_energy_fltr = tic;
    
    % minimum number of segments to keep
    min_n_segms = 5;
    
    [sorted_cut_ratio, sorted_ind] = ...
        sort(curr_segments.segs_meta_info.energies, 'ascend');
    last_acceptable = find(sorted_cut_ratio <= max_energy, 1, 'last');
    reject_segs_ind = sorted_ind(last_acceptable+1:end);
    % if the remaining number of segments would be less
    num_remain_segs = length(sorted_cut_ratio) - length(reject_segs_ind);
    if num_remain_segs < min_n_segms
        num_keep_more = min_n_segms - num_remain_segs;
        num_keep_more = min(num_keep_more, length(reject_segs_ind));
        reject_segs_ind(1:num_keep_more) = [];
    end

    % remove segments not wanted from curr_segments
    [curr_segments] = cherry_pick_segments(curr_segments, ...
                                           setdiff(1:length(sorted_ind), ...
                                                   reject_segs_ind));
    
    seg_obj.num_segs.after_energy_filtering = ...
        [seg_obj.num_segs.after_energy_filtering, ...
         size(curr_segments.cut_segs,2)];
    
    fprintf('%.2fs\n', toc(t_energy_fltr));
    
    time_util(seg_obj, 'energy_filter_time', t_energy, 1, 0);
end

function [curr_segments] = filter_rand(curr_segments, seg_obj, ...
                                       max_rand_pick)
    fprintf('\t\tPick %d random segments ... ', max_rand_pick);
    
    t_rand = tic;
    
    if size(curr_segments.cut_segs,2) > max_rand_pick
        randn = randperm(size(curr_segments.cut_segs,2));
        curr_segments = cherry_pick_segments(curr_segments, ...
                                             randn(1:max_rand_pick));
    end
    
    seg_obj.num_segs.after_random_picking = ...
        [seg_obj.num_segs.after_random_picking, ...
         size(curr_segments.cut_segs,2)];
    
    time_util(seg_obj, 'rand_filter_time', t_rand, 1, 1);
end

function [curr_segments] = remove_repeated_segments(curr_segments, ...
                                                    seg_obj, gp_obj)
    fprintf('\t\tRemoving repeated segments ... ');
    
    OVERLAP_THRESH = 0.95;

    t_repeat = tic;
    
    seg_sel = [];
    
    % divide segments by their graph sub-methods
    ub = cumsum(gp_obj.graph_sets_per_method);
    lb = [1, ub(1:end-1)+1];
%     % if you don't want division by graph sub-methods (comment out above)
%     ub = inf;
%     lb = 1;
    
    % find sols_to_unary_mapping for the segments remaining
    sols_to_unary_map = curr_segments.segs_meta_info.sols_to_unary_mapping;
    seg_mapping = curr_segments.segs_meta_info.seg_mapping_final_to_orig;
    curr_unary_mapping = sols_to_unary_map(seg_mapping);
    for gsubm = 1:length(ub)
        subm_idx = curr_unary_mapping >= lb(gsubm) & ...
                   curr_unary_mapping <= ub(gsubm);
        cut_segs = curr_segments.cut_segs(:,subm_idx);
        
        % smart way to compute pairwise overlaps btw segments if above 0.95
        overlap_mat = overlap_over_threshold(cut_segs, OVERLAP_THRESH);
    
        % find segment sets which are stringed together with high overlap
        bw_mat = overlap_mat >= OVERLAP_THRESH;
        [num_conn, conncomps_t] = graphconncomp(sparse(bw_mat));
        conncomps = zeros(size(subm_idx));
        conncomps(subm_idx) = conncomps_t;
        this_sel = zeros(1,num_conn);
        % for each segment set, select one segment with lowest energy
        for i = 1:num_conn
            s1 = find(conncomps == i);
            [~,b] = min(curr_segments.segs_meta_info.energies(conncomps == i));
            this_sel(i) = s1(b);
        end
        % collate to the list of segments to be cherry picked
        seg_sel = [seg_sel, this_sel];
    end
    
    % keep only segments which have lowest energy amongst similar segments
    [curr_segments] = cherry_pick_segments(curr_segments, seg_sel);
    
    seg_obj.num_segs.after_repeat_remove = ...
        [seg_obj.num_segs.after_repeat_remove, length(seg_sel)];

    time_util(seg_obj, 'seg_similar_filter_time', t_repeat, 1, 1);
end

function [curr_segments] = cherry_pick_segments(curr_segments, to_pick_idxs)
% this function removes segments from curr_segments structure

    curr_segments.cut_segs = curr_segments.cut_segs(:, to_pick_idxs);
    curr_segments.segs_meta_info.seg_mapping_final_to_orig = ...
        curr_segments.segs_meta_info.seg_mapping_final_to_orig(:, to_pick_idxs);

    if isfield(curr_segments.segs_meta_info, 'energies') && ...
            ~isempty(curr_segments.segs_meta_info.energies)
        curr_segments.segs_meta_info.energies = ...
            curr_segments.segs_meta_info.energies(to_pick_idxs);
    end
end
