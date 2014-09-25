classdef ColorGraph < AbstractGraph
%COLORGRAPH is a class which generates graphs with seeds and unaries using 
% color information. This class is derived from AbstractGraph. To undestand
% how unaries are generated, its worth seeing how 
% AbstractGraph.prepare_graphs() calls create_unaries() in this class to
% compute unary values.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014
    
    properties
        precompute
    end
    
    methods
        function obj = ColorGraph(seg_obj, segm_index)
            obj.init(seg_obj, segm_index);
            
            obj.precompute.bg_unary_values = [];
            obj.precompute.clr_unary_hash = {};
            obj.precompute.clr_unary_values = {};
        end
        
        function create_unaries(obj, graph_sub_method, seed_sets)
            switch graph_sub_method
                case 'internal'
                    obj.generate_color_unaries('internal', seed_sets);
                case 'external'
                    obj.generate_color_unaries('external', seed_sets);
                case 'subframe'
                    error('ColorGraph:compute_graph', ...
                          '''subframe'' not implemented yet');
                otherwise
                    error('ColorGraph:compute_graph', ...
                          '''%s'' is an invalid graph method', ...
                          graph_sub_method);
            end
        end
        
        function generate_color_unaries(obj, internal_external, seed_sets)
            inside_frame = ~obj.seg_obj.sp_frame_set;
            
            funcs = create_unary_aux_funcs(obj, internal_external);
            
            [bg_unary_values, clr_unary_vals] = ...
                precompute_return_data(obj, funcs, seed_sets, ...
                                       inside_frame, internal_external);
            
            % find the offset according to the number of unary graphs
            % already added to graph_unaries_all
            ofst = size(obj.graph_unaries_all.nonlambda_s,2);
            
            % initialize the matrices for holding all the unaries (see the
            % comment for this structure in AbstractGraph.prepare_graphs())
            obj.graph_unaries_all.nonlambda_s = ...
                [obj.graph_unaries_all.nonlambda_s, zeros(size(seed_sets))];
            obj.graph_unaries_all.nonlambda_t = ...
                [obj.graph_unaries_all.nonlambda_t, zeros(size(seed_sets))];
            obj.graph_unaries_all.lambda_s = ...
                [obj.graph_unaries_all.lambda_s, zeros(size(seed_sets))];
            obj.graph_unaries_all.lambda_t = ...
                [obj.graph_unaries_all.lambda_t, zeros(size(seed_sets))];
            
            % iterate over all seed locations
            for i = 1:size(seed_sets, 2)
                if strcmp(internal_external, 'internal')
                    [nonlambda_s, lambda_t] = internal_color(obj, ...
                                                   seed_sets(:,i), ...
                                                   clr_unary_vals(:,i));
                    
                    obj.graph_unaries_all.nonlambda_s(:,ofst+i) = ...
                                                               nonlambda_s;
                    obj.graph_unaries_all.lambda_t(:,ofst+i) = lambda_t;
                else
                    [nonlambda_s, nonlambda_t, lambda_s, lambda_t] = ...
                        external_color(obj, seed_sets(:,i), ...
                                       inside_frame, bg_unary_values, ...
                                       clr_unary_vals(:,i), ...
                                       funcs.parametric_func, ...
                                       funcs.frame_cost_func);
                    
                    obj.graph_unaries_all.nonlambda_s(:,ofst+i) = ...
                                                               nonlambda_s;
                    obj.graph_unaries_all.nonlambda_t(:,ofst+i) = ...
                                                               nonlambda_t;
                    obj.graph_unaries_all.lambda_s(:,ofst+i) = lambda_s;
                    obj.graph_unaries_all.lambda_t(:,ofst+i) = lambda_t;
                end
            end
        end
        
        function [nonlambda_s, lambda_t] = internal_color(obj, ...
                                                fg_seeds, unary_values)
            % see the comment for these output matrices in 
            % AbstractGraph.prepare_graphs()
            nonlambda_s = zeros(length(fg_seeds),1);
            lambda_t = zeros(length(fg_seeds),1);
            
            bground_pixels = ~fg_seeds;
            nonlambda_s(fg_seeds) = inf;
            nonlambda_s(bground_pixels) = unary_values(bground_pixels)*2;
            lambda_t(bground_pixels) = 1;
        end
        
        function [nonlambda_s, nonlambda_t, lambda_s, lambda_t] = ...
                external_color(obj, fg_seeds, inside_frame, ...
                               bg_unary_values, fg_unary_values, ...
                               parametric_func, frame_cost_func)
            % see the comment for these output matrices in 
            % AbstractGraph.prepare_graphs()
            nonlambda_s = zeros(length(fg_seeds),1);
            nonlambda_t = zeros(length(fg_seeds),1);
            lambda_s = zeros(length(fg_seeds),1);
            lambda_t = zeros(length(fg_seeds),1);
            
            non_seed_pixels = inside_frame & ~fg_seeds;
            lambda_weights = parametric_func(non_seed_pixels);
            bground_pixels = ~(inside_frame | obj.seg_obj.sp_frame_set);
            
            % internal seed - topological constraint
            nonlambda_s(fg_seeds) = inf;
            % external seed - topological constraint
            nonlambda_t(bground_pixels) = inf;
            
            % not we dont need to add values because non_seed_pixels is a
            % subset of inside_frame and bground_pixels is outside
            % inside_frame
            nonlambda_t(non_seed_pixels) = bg_unary_values(non_seed_pixels) * 2;
            % unary potential reflecting similarity to fg_seeds pixels
            nonlambda_s(non_seed_pixels) = fg_unary_values(non_seed_pixels) * 2;
            % parametric potential
            lambda_s(non_seed_pixels) = lambda_weights;
            % parametric potential
            lambda_t(non_seed_pixels) = lambda_weights;
            
            frame_cost = frame_cost_func(fg_seeds);
            
%           frame_cost = obj.frame_bg_bias(fg_seeds, size(obj.I));
            %frame_cost = 1;
            % always have some frame soft bias to belong in the background
            nonlambda_t(obj.seg_obj.sp_frame_set) = ...
                nonlambda_t(obj.seg_obj.sp_frame_set) + ...
                frame_cost*obj.SEED_FRAME_WEIGHT;
        end
        
        function [bg_unary_values, clr_unary_vals] = ...
                precompute_return_data(obj, funcs, seed_sets, ...
                                       inside_frame, unary_desc)
            
            % precompute the non-changing bg color unary values
            if isempty(obj.precompute.bg_unary_values)
                % unary potential reflecting similarity to bground pixels
                bndry_for_estimation = funcs.bndry_est_func(inside_frame);
                obj.precompute.bg_unary_values = ...
                    funcs.color_unary_func(bndry_for_estimation);                
            end
            bg_unary_values = obj.precompute.bg_unary_values;

            seed_hash = num2str(sum(seed_sets(:)));
%             seed_hash = DataHash(seed_sets, ...
%                                  obj.seg_obj.other_params.hash_params);
            % check if this seed type has not already been computed
            precomputed_unary_idx = find(strcmp(seed_hash, ...
                                         obj.precompute.clr_unary_hash));
            if isempty(precomputed_unary_idx)
                clr_unary_values = zeros(size(seed_sets)); 
                for i = 1:size(seed_sets, 2)
                    clr_unary_values(:,i) = ...
                        funcs.color_unary_func(seed_sets(:,i));
                end
                obj.precompute.clr_unary_values{end+1} = clr_unary_values;
                obj.precompute.clr_unary_hash{end+1} = seed_hash;
                precomputed_unary_idx = ...
                    length(obj.precompute.clr_unary_values);
            end
            clr_unary_vals = ...
                obj.precompute.clr_unary_values{precomputed_unary_idx};
            
            % if using the color segmenter for 'internal' type, normalize 
            % by superpixel size
            if strcmpi(unary_desc, 'internal')
                clr_unary_vals = bsxfun(@rdivide, clr_unary_vals, ...
                                        obj.seg_obj.sp_data.sp_seg_szs);
            end
        end
    end
end
