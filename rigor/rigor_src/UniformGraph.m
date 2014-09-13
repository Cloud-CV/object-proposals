classdef UniformGraph < AbstractGraph
%UNIFORMGRAPH is a class which generates graphs with seeds and unaries
% which are not dependent on image information (for instance unaries are
% only based on superpixel size). This class is derived from AbstractGraph. 
% To undestand how unaries are generated, its worth seeing how 
% AbstractGraph.prepare_graphs() calls create_unaries() in this class to
% compute unary values.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    properties
    end
    
    methods
        function obj = UniformGraph(seg_obj, segm_index)
            obj.init(seg_obj, segm_index);
        end
        
        function create_unaries(obj, graph_sub_method, seed_sets)
            switch graph_sub_method
                case 'internal'
                    obj.generate_uniform_unaries('internal', seed_sets);
                case 'external'
                    obj.generate_uniform_unaries('external', seed_sets);
                case 'subframe'
                    error('UniformGraph:compute_graph', ...
                          '''subframe'' not implemented yet');
                otherwise
                    error('UniformGraph:compute_graph', ...
                          '''%s'' is an invalid graph method', ...
                          graph_sub_method);
            end
        end
        
        function generate_uniform_unaries(obj, internal_external, ...
                                          seed_sets)
            inside_frame = ~obj.seg_obj.sp_frame_set;
            
            funcs = create_unary_aux_funcs(obj, internal_external);
            
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
                    [nonlambda_s, lambda_t] = internal_uniform(obj, ...
                                                     seed_sets(:,i), ...
                                                     funcs.parametric_func);
                    
                    obj.graph_unaries_all.nonlambda_s(:,ofst+i) = ...
                                                               nonlambda_s;
                    obj.graph_unaries_all.lambda_t(:,ofst+i) = lambda_t;
                else
                    [nonlambda_s, nonlambda_t, lambda_s, lambda_t] = ...
                        external_uniform(obj, seed_sets(:,i), ...
                                         inside_frame, ...
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
        
        function [nonlambda_s, lambda_t] = internal_uniform(obj, ...
                                         the_rectangle, parametric_func)
            % see the comment for these output matrices in 
            % AbstractGraph.prepare_graphs()
            nonlambda_s = zeros(length(the_rectangle),1);
            lambda_t = zeros(length(the_rectangle),1);
            
            bground_pixels = ~the_rectangle;
            nonlambda_s(the_rectangle) = inf;
            lambda_t(bground_pixels) = parametric_func(bground_pixels);
        end
        
        function [nonlambda_s, nonlambda_t, lambda_s, lambda_t] = ...
                external_uniform(obj, the_rectangle, inside_frame, ...
                                 parametric_func, frame_cost_func)
            % see the comment for these output matrices in 
            % AbstractGraph.prepare_graphs()
            nonlambda_s = zeros(length(the_rectangle),1);
            nonlambda_t = zeros(length(the_rectangle),1);
            lambda_s = zeros(length(the_rectangle),1);
            lambda_t = zeros(length(the_rectangle),1);
            
            inside_frame_but_rect = inside_frame & ~the_rectangle;
            lambda_weights = parametric_func(inside_frame_but_rect);
            bground_pixels = ~(inside_frame | obj.seg_obj.sp_frame_set);
            
            nonlambda_s(the_rectangle) = inf;
            nonlambda_t(bground_pixels) = inf;
            lambda_s(inside_frame_but_rect) = lambda_weights;
            
            frame_cost = frame_cost_func(the_rectangle);
            
            nonlambda_t(obj.seg_obj.sp_frame_set) = ...
                frame_cost * obj.graph_seed_frame_weight;
            %hyp_conns{1,5} = {inside_frame_but_rect, obj.Background, 0, 1};
            lambda_t(inside_frame_but_rect) = lambda_weights;
        end
    end
end
