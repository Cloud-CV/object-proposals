classdef AbstractGraph < handle
%ABSTRACTGRAPH is the class which handles the generation of graph unaries
% and pairwise values. It also handles the computation of seeds. This class
% is abstract, and other classes inherit and define the create_unaries()
% method. This method is invoked by prepare_graphs().
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014
    
    properties (Constant)
        SEED_FRAME_WEIGHT = 1000;
    end
    
    properties
        seg_obj
        
        graph_sub_methods
        graph_seed_frame_weight
        graph_unary_exp_scale
        graph_pairwise_multiplier
        graph_pairwise_contr_weight
        graph_pairwise_potts_weight
        graph_pairwise_sigma
        graph_sub_methods_cut_param
    
        precomputed_seeds
        seed_mapping_idx
        
        edge_vals
        
        fg_node_id
        bg_node_id
        
        graph_unaries_all
        graph_sets_per_method
    end
    
    methods (Access = public)
        function init(obj, seg_obj, segm_index)
            fprintf('---< Creating segments using %s >---\n', class(obj));
            
            % make a copy of the Segmenter object
            obj.seg_obj = seg_obj;
            
            % get all the properties of this object and then copy values
            % at segm_index from seg_obj.segm_params to this Graph object
            props = properties(obj);
            props(cellfun(@(r) find(strcmpi(r, props)), {'seg_obj'})) = [];
            % iterate over all props and copy from seg_obj.segm_params
            for prop_idx = 1:length(props)
                prop_name = props{prop_idx};
                if isfield(seg_obj.segm_params, prop_name)
                    obj.(prop_name) = ...
                        seg_obj.segm_params.(prop_name){segm_index};
                end
            end
            
            % get all the precomputed seeds which would be used by this
            % Graph object. Each sub-method (given by 
            % obj.graph_sub_methods)in this Graph object might be using a 
            % different seed set.
            mapping_idx = obj.seg_obj.seed_mapping_idx{segm_index};
            [seed_idx_to_pick, ~, mapping_idx] = unique(mapping_idx);
            obj.precomputed_seeds = ...
                obj.seg_obj.precomputed_seeds(seed_idx_to_pick);
            obj.seed_mapping_idx = mapping_idx;
            
            % set the foreground and background seed id (used for
            % identifying variables when performing graph-cuts)
            num_nodes = size(obj.precomputed_seeds(1).seed_sets, 1);
            obj.fg_node_id = num_nodes + 1;
            obj.bg_node_id = num_nodes + 2;
        end
        
        function prepare_graphs(obj)
            obj.graph_sets_per_method = ...
                zeros(1,length(obj.graph_sub_methods));
            
            obj.graph_unaries_all = struct;
            
            % graph_unaries_all is the main structure which hold all the
            % unary values for each graph generated over different seeds.
            % All the four matrices would be of size N x (M.S_i), where N 
            % is the number of variables (pixels/superpixels) in the graph, 
            % M is the number of graph sub methods 
            % [equal to length(obj.graph_sub_methods)], and S_i is the
            % number of seed locations in each graph sub method:
            % nonlambda_s stores the non-parametric capacities from the
            % source node to each variable
            obj.graph_unaries_all.nonlambda_s = [];
            % nonlambda_t stores the non-parametric capacities from the
            % sink node to each variable
            obj.graph_unaries_all.nonlambda_t = [];
            % lambda_s stores the parametric capacities from the source 
            % node to each variable. These values will be multiplied with
            % different lambdas to produce multiple cuts
            obj.graph_unaries_all.lambda_s = [];
            % lambda_t stores the parametric capacities from the sink 
            % node to each variable. These values will be multiplied with
            % different lambdas to produce multiple cuts
            obj.graph_unaries_all.lambda_t = [];
            
            % iterate over all graph sub methods
            fprintf('\tComputing unary capacities ... ');
            t_unaries = tic;
            for method_idx = 1:length(obj.graph_sub_methods)
                % get the seed sets for the current graph sub-method
                seed_idx = obj.seed_mapping_idx(method_idx);
                seed_sets = obj.precomputed_seeds(seed_idx).seed_sets;
                
                % generate unary costs for all the seed sets for the
                % current graph sub-method
                create_unaries(obj, obj.graph_sub_methods{method_idx}, ...
                               seed_sets);
                
                % compute the number of graphs (unaries) generated for this
                % sub-method
                obj.graph_sets_per_method(method_idx) = ...
                    size(obj.graph_unaries_all.lambda_s,2) - ...
                    sum(obj.graph_sets_per_method);
            end
            time_util(obj.seg_obj, 'unary_cost_set_time', t_unaries, 1, 1);
            
            % take the pixel-wise precomputed edge values, and compute
            % the superpixel-to-superpixel edge potentials
            fprintf('\tComputing pairwise capacities ... ');
            t_pairwise = tic;
            set_pairwise_graph(obj);
            time_util(obj.seg_obj, 'pairwise_set_time', t_pairwise, 1, 1);
            
            % if debug, draw all unaries
            diagnostic_methods('draw_unaries_all', obj.seg_obj, obj);
        end
    end
    
    methods (Abstract)
        create_unaries(obj, graph_sub_method, seed_sets);
    end
    
    methods (Access = public, Static)
        [seed_sets] = generate_graph_seeds(graph_seed_gen_method, ...
                                           graph_seed_params, seg_obj);
        
        [seed_sets] = gen_sp_seed_sampling(graph_seed_params, seg_obj);
        
        [edge_vals] = ...
            get_pairwise_capacities(edge_vals, graph_pairwise_sigma, ...
                                    graph_pairwise_contr_weight, ...
                                    graph_pairwise_potts_weight)
    end
    
    methods (Access = protected)
        [val] = compute_sp_unary_values(obj, seed_region, sp_normalize);
        [val] = ...
            compute_sp_mean_unary_values(obj, seed_region, sp_normalize);
        
        set_pairwise_graph(obj);
        
        function [funcs] = create_unary_aux_funcs(obj, unary_desc)
            % a parametric value of size of the superpixel (for uniform 
            % segmenters)
            funcs.parametric_func = ...
                @(bg_sps_ind) obj.seg_obj.sp_data.sp_seg_szs(bg_sps_ind);
            funcs.frame_cost_func = @(the_rectangle) ...
                    obj.frame_sp_bg_bias(the_rectangle);
            
            funcs.color_unary_func = @(the_rectangle) ...
                         obj.compute_sp_mean_unary_values(the_rectangle);
%             
%             funcs.color_unary_func = @(the_rectangle) ...
%                          obj.compute_sp_unary_values(the_rectangle);
            
            funcs.bndry_est_func = @(inside_frame) ...
                   obj.return_sp_bndry_for_estimation(inside_frame);
        end
        
        % for spatially weighting smooth negative seeds (non-inf potentials
        % for the frame )
        function [frame_cost] = frame_sp_bg_bias(obj, internal_region)
            % compute the center of the group of spxs
            sp_centers = ...
                obj.seg_obj.sp_data.sp_centroids(internal_region,:);
            szs = obj.seg_obj.sp_data.sp_seg_szs(internal_region);
            szs = szs ./ sum(szs);
            center = sum(bsxfun(@times, sp_centers, szs), 1);
            
            curr_img_frame_centers = ...
                obj.seg_obj.sp_data.sp_centroids(obj.seg_obj.sp_frame_set,:);
            
            dist = bsxfun(@minus, curr_img_frame_centers, center);
            frame_cost = sqrt(sum(dist.*dist,2));
            frame_cost = frame_cost/max(frame_cost);
            
            % scale by sizes of the frame superpixels
            frame_cost = ...
                obj.seg_obj.sp_data.sp_seg_szs(obj.seg_obj.sp_frame_set) ...
                .* frame_cost;
        end
                                     
        function [bndry_for_estimation] = ...
                        return_sp_bndry_for_estimation(obj, inside_frame)
            pxl_inside_frame = ismember(obj.seg_obj.sp_data.sp_seg, ...
                                        find(inside_frame));
            bndry_estimation_pxl = bwperim(pxl_inside_frame, 4);
            bndry_sp = obj.seg_obj.sp_data.sp_seg(bndry_estimation_pxl);
            bndry_for_estimation = false(size(inside_frame));
            bndry_for_estimation(bndry_sp) = true;
        end
    end
end
