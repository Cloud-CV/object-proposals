function [cuts, lambdas, seed_mapping, mincut_vals, t_pmc, cut_info] = ...
        multiseed_param_min_st_cut(gp_obj, method_str, graph_start_idxs, ...
                                   graphcut_params)
% options: 
%   nodynamic*: recreate the graph for every seed and parameter but use TBB 
%               parallelization to simultaneously solve different seeds
%
%   kohli_reusetrees*: create graph once for each seed and reparameterize 
%               the graph (Kohli PAMI 2007) for every seed and use TBB 
%               parallelization to solve seeds simultaneously
%
%   kohli*: create graph once but don't reuse trees
%
%   multiseed*: Uses the graph reuse scheme over multiple seeds. Given
%               multiple seeds it first generates a precomputation graph. 
%               That graph is reparameterized for each seed and solved 
%               consequently for each seed separately
%
%   multiseed_opplambda*: Uses same scheme as multiseed but the
%               precomputation graph is built from the opposite end of the 
%               first scheduled lambda (so if the first lambda is scheduled 
%               is at index 1, then the lambda used to build the 
%               precomputation graph would be the lambda at the last index)
%
% (Every option can be appended with '_noparallel' to stop parallel
% computation of seeds)
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014
    
    % generate the options string for each graph type
    options_str = '';
    
    REV = false(1, length(graph_start_idxs));
    
    for graph_type_idx = 1:length(graph_start_idxs)
        options_str = [options_str, '|', method_str];
        
        % if the graph-cut method is Kohli&Torr or ours and was the lambda
        % scheduling needs to be set in reverse
        if ~isempty(graphcut_params) && ...
           (~isempty(strfind(gp_obj.segm_params.pmc_maxflow_method, 'kohli')) || ...
            ~isempty(strfind(gp_obj.segm_params.pmc_maxflow_method, 'multiseed'))) ...
            && graphcut_params(graph_type_idx) == 0
            REV(graph_type_idx) = true;
        end

        if REV(graph_type_idx)
            options_str = [options_str '_rev'];
        end
    end
    options_str(1) = [];

    mincut_vals = NaN;
    
    % adjust graph (like thresholding values and data conversion) before
    % creating the final data structure used by graph cuts
    [nonlambda_s, nonlambda_t, lambda_s, lambda_t, lambda_range, ...
        pairwise_edges, DISC_FACTOR, BIG_VALUE] = ...
            preprocess_graphs(gp_obj, ...
                              gp_obj.graph_unaries_all.nonlambda_s, ...
                              gp_obj.graph_unaries_all.nonlambda_t, ...
                              gp_obj.graph_unaries_all.lambda_s, ...
                              gp_obj.graph_unaries_all.lambda_t);
                       
    t_pmc = tic;
    % compute maxflow via boykov-kolmogorov
    [all_cuts, meta_info] = bk_dynamicgraphs_mex(nonlambda_s, ...
                                                 nonlambda_t, lambda_s, ...
                                                 lambda_t, lambda_range, ...
                                                 pairwise_edges, ...
                                                 graph_start_idxs, ...
                                                 options_str);
    t_pmc = toc(t_pmc);
    t_pmc = repmat(t_pmc / length(graph_start_idxs), ...
                   length(graph_start_idxs), 1);
               
    fprintf(' ... ');
    
    cuts = false(size(nonlambda_s,1), 0);
    lambdas = [];
    seed_mapping = [];
    cuts_to_seed_mapping = zeros(1,size(meta_info,2));
    last_map_idx = 0;
    mincut_vals = [];
    full_set_cut = 0;
    
    graph_start_idxs2 = [graph_start_idxs, size(nonlambda_s,2)+1];
    
    % iterate over all seed locations
    for seed_idx = 1:size(all_cuts,2)
        curr_graph_type_idx = find(seed_idx < graph_start_idxs2, 1, 'first') - 1;
        
        curr_cuts = all_cuts(:,seed_idx);
                
        if REV(curr_graph_type_idx)
            % in reverse variables which are 0 are the variables that 
            % always remained src side of the cut
            
            % variables that always remained sink
            no_fg_vars = curr_cuts == length(lambda_range);
            
            % convert to values to bp where the src started
            curr_cuts = curr_cuts + 1;
            curr_cuts(no_fg_vars) = 0;
        else
            no_fg_vars = curr_cuts == 0;
        end
        
        % get all the breakpoints (value of 0 means that it never got
        % converted to src)
        bp = double(unique(curr_cuts));
        bp(bp == 0) = [];
        
        curr_lambda_range = lambda_range(bp)';
        
        % map unique bp from 1:number of breakpoints
        mapping = zeros(length(lambda_range),1);
        mapping(bp) = 1:length(bp);
        
        curr_cuts(~no_fg_vars) = mapping(curr_cuts(~no_fg_vars));
        
        if REV(curr_graph_type_idx)
            min_bp = min(bp(bp ~= 1));
            num_cuts = length(lambda_range) - (min_bp-1) + 1;
        else
            num_cuts = max(bp);
        end
        
        % convert to logical matrix
        output_segs = bsxfun(@ge, 1:length(bp), curr_cuts);
        output_segs(no_fg_vars,:) = 0;
        
        % check if last segment is all fg (then discard) [we cant get all
        % bg solutions because there is an infinity cost at fg seeds]
        if ~isempty(output_segs) && all(output_segs(:,end))
            output_segs(:,end) = [];
            curr_lambda_range(end) = [];
            bp(end) = [];
        else
            if ~REV(curr_graph_type_idx)
                % if the last segment wasn't full then we computed cuts for 
                % all lambdas
                num_cuts = length(lambda_range);
            end
        end
        
        if REV(curr_graph_type_idx)
            num_fg_seed_vars = nnz(nonlambda_s(:,seed_idx) >= BIG_VALUE);
            % check if the last segment is only fg - if not then we
            % computed all lambda cuts
            if isempty(output_segs) || num_fg_seed_vars < ...
                                       nnz(output_segs(:,1))
                num_cuts = length(lambda_range);
            end
        end
        
        cuts_to_seed_mapping(last_map_idx+1:last_map_idx+num_cuts) = ...
            seed_idx;
        last_map_idx = last_map_idx + num_cuts;
        
        % collate results
        if ~isempty(output_segs)
            lambdas = [lambdas, curr_lambda_range'];
            seed_mapping = [seed_mapping, ...
                            repmat(seed_idx, 1, size(output_segs,2))];
            cuts = [cuts, output_segs];
        end
        
        if num_cuts == length(lambda_range)
            full_set_cut = full_set_cut + 1;
        end
        
        % collect meta info for this cut
%         curr_meta_info = meta_info(:, cuts_to_seed_mapping == seed_idx);
        
%         mincut_vals = [mincut_vals, curr_meta_info(6,orig_bp)];
        
%         subplot(7,4,seed_idx);
%         plot(curr_meta_info([1 2],:)'); %legend('graph constr', 'maxflow');
%         %title(sprintf('Seed %d', seed_idx));
%         ylim([0, 3e-3]);
    end
    
    cut_info.maxflow_stats = meta_info;
    cut_info.cuts_to_seed_mapping = cuts_to_seed_mapping;
%     assert(size(meta_info,2) == length(cuts_to_seed_mapping), ...
%         'meta info not the same size as the number of cuts made');
%     assert(all(cuts_to_seed_mapping ~= 0), ...
%         'something went wrong in mapping cuts to seed');
end

