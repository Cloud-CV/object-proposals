function [seed_sets] = generate_graph_seeds(graph_seed_gen_method, ...
                                            graph_seed_params, seg_obj)
% returns an NxS seed_sets logical matrix, where each column defines a
% seed. A value of 1 in a row indicates that that pixel/superpixel is
% included in the seed specified by the column.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    if strcmpi(graph_seed_gen_method, 'sp_img_grid')
        [seed_sets] = gen_sp_img_grid(graph_seed_params, seg_obj);
    elseif strcmpi(graph_seed_gen_method, 'sp_all')
        [seed_sets] = gen_sp_all_seeds(graph_seed_params, seg_obj);
    elseif strcmpi(graph_seed_gen_method, 'sp_clr_seeds')
        [seed_sets] = gen_sp_clr_seeds(graph_seed_params, seg_obj);
    elseif strcmpi(graph_seed_gen_method, 'sp_seed_sampling')
        [seed_sets] = AbstractGraph.gen_sp_seed_sampling(graph_seed_params, seg_obj);
    elseif strcmpi(graph_seed_gen_method, 'gen_user_seeds')
        [seed_sets] = gen_user_seeds(graph_seed_params, seg_obj);
    else
        error('AbstractGraph:generate_graph_seeds', ...
              '''%s'' invalid seed generation methos', ...
              graph_seed_gen_method);
    end
    
    % this function ensures no seeds overlap
    [seed_sets] = no_overlapping_seeds(seed_sets, seg_obj);
end


function [seed_sets] = gen_sp_img_grid(graph_seed_params, seg_obj)
% generates seeds by a grid over the image. The first array in 
% graph_seed_params specifies how many seeds are needed. The second array
% specifies the extent of the seed pixels around each seed grid location

    graph_num_seed_locs = graph_seed_params{1};
    graph_seed_sz = graph_seed_params{2};
    % generate the offsets from the central grid pixel
    [rect_coords] = ...
        generate_seeds_funcs('generate_rectangle_coords', ...
                             graph_seed_sz);
    % generate the seed sets over a grid (each column gives 
    % pixels/superpixels selected for that seed)
    seed_sets = generate_seeds_funcs('generate_sp_img_grid', ...
                                     seg_obj.sp_data.sp_seg, ...
                                     rect_coords, ...
                                     graph_num_seed_locs, ...
                                     seg_obj.sp_data.sp_seg_szs, 0);
end


function [seed_sets] = gen_sp_all_seeds(graph_seed_params, seg_obj)
% generates seeds by choosing all sps. The single parameter in 
% graph_seed_params indicate how many sps to skip when choosing a sp as a
% seed

    subsample_sps = graph_seed_params{1} + 1;
    
    % initially each sp is a seed
    seed_sets = logical(eye(seg_obj.sp_data.num_spx, 'int8'));
    
    % now subsample the seeds
    seed_sets = seed_sets(:,1:subsample_sps:end);
end


function [seed_sets] = gen_sp_clr_seeds(graph_seed_params, seg_obj)
% generates seeds by finding superpixels locations which are closest to a
% grid over the image. The first array in graph_seed_params specifies how 
% many seeds are needed. The second array specifies the extent of the seed 
% pixels around each seed grid location. The third argument is a string
% specifying what superpixel method to use. 'sp_seeds_caller' uses the
% superpixels already generated in seg_obj.sp_data;
% 'felzenszwalb_seeds_caller' uses FelzHutten superpixels.

    graph_num_seed_locs = graph_seed_params{1};
    graph_seed_sz = graph_seed_params{2};
    superpixel_method = graph_seed_params{3};
    % generate the offsets from the central grid pixel
    [rect_coords] = ...
        generate_seeds_funcs('generate_rectangle_coords', ...
                             graph_seed_sz);
    % generate the seed sets over a grid (each column gives 
    % pixels/superpixels selected for that seed)
    seed_sets = generate_seeds_funcs('generate_sp_seeds_superpixels', ...
                                     seg_obj.sp_data, seg_obj.I, ...
                                     superpixel_method, 0, ...
                                     rect_coords, graph_num_seed_locs);
end


function [seed_sets] = gen_user_seeds(graph_seed_params, seg_obj)
    graph_seed_sz = graph_seed_params{1};
    user_centers = graph_seed_params{2};
    [rect_coords] = ...
        generate_seeds_funcs('generate_rectangle_coords', ...
                             graph_seed_sz);
    seed_sets = generate_seeds_funcs('generate_sp_user', ...
                                     seg_obj.sp_data.sp_seg, ...
                                     rect_coords, user_centers, ...
                                     seg_obj.sp_data.sp_seg_szs, 0);
end


function [seed_sets] = no_overlapping_seeds(seed_sets, seg_obj)
% this function ensures that no seeds overlap i.e. no superpixels are the
% same in two seeds

    % find number of overlapping superpixels across seeds
    ss = single(seed_sets);
    num_overlap_sps = ss' * ss;
    num_overlap_sps = triu(num_overlap_sps, 1);
    [s1,s2,os] = find(num_overlap_sps);
    num_overlap_sps = [s1, s2, os];
    
    num_sps_per_seed = sum(seed_sets);
    
    % remove overlapping superpixel for each seed pair contention (note,
    % superpixels removed from a seed in a pervious iteration, would no
    % longer be taken into consideration in later iterations - hence,
    % correctly ignoring superpixels which no longer belong to a seed)
    for idx = 1:size(num_overlap_sps,1)
        s1 = num_overlap_sps(idx,1);
        s2 = num_overlap_sps(idx,2);
        n1 = num_sps_per_seed(s1);
        n2 = num_sps_per_seed(s2);
        
        % find the sps which overlap
        overlap_sps = all(seed_sets(:,[s1 s2]), 2);
        
        % if seed1 has more superpixels, then remove overlapping sp from
        % seed1. Otherwise remove superpixel from seed2
        if n1 > n2
            seed_sets(overlap_sps,s1) = 0;
        else
            seed_sets(overlap_sps,s2) = 0;
        end
    end
    
    % discard any seeds which have no superpixels anymore
    num_sps_per_seed = sum(seed_sets);
    seed_sets(:,num_sps_per_seed == 0) = [];
end