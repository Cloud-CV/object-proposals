function [segm_params, filepath_params, other_params] = ...
        params_default(segm_params, filepath_params, other_params, ...
                       extra_params)
% The default parameter set, which is used if no other parameter set is
% given. For invoking a different parameter set, for instance,
% params_StructEdges you need to give this command:
% rigor_obj_segments('im.jpg', 'params_func', @params_StructEdges)
%
% @author:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014


    fp = filepath_params;                                                   % Parameters related to directory locations
    sp = segm_params;                                                       % Parameters for FastSeg's technical internals
    op = other_params;                                                      % Misc. parameters
    ep = extra_params;                                                      % Params passed as an argument for overriding parameters here
    
    code_root_dir = fileparts(which(mfilename));                            % root directory of the code (supposes this function lies in the root directory)
    
    
    % set the filepath parameters
    fp.code_root_dir = code_root_dir;
    fp = get_param_val(fp, ep, 'data_save_dirpath', ...
                           fullfile(code_root_dir, 'data'));                % Directory where data is saved (like computed boundaries, debug info, etc.)
    
    
    % set the Segmenter parameters
    sp = get_param_val(sp, ep, 'pmc_num_lambdas',       20);                % Number of lambda parameters to enumerate for parametric min-cut (see GraphProcessor.generate_param_lambdas() on how lambda as generated).
    sp = get_param_val(sp, ep, 'pmc_maxflow_method',    'hochbaum');        % Type of max-flow method to use. Invoked at GraphProcessor.generate_mincut_segments(). Current options are 'hochbaum' (Pseudo-flow), 
                                                                            % 'nodynamic' (vanilla Boykov-Kolmogorov), 'kohli' (Kohli-Torr dynamic graph method), and finally 'multiseed' (our method). For additional 
                                                                            % options with 'nodynamic', 'kohli', and 'multiseed', see comments in GraphProcessor.multiseed_param_min_st_cut().
    sp = get_param_val(sp, ep, 'boundaries_method',     'Gb');              % Type of boundary detector to use. Invoked at Segmenter.compute_boundaries().
    sp = get_param_val(sp, ep, 'filter_min_seg_pixels', 100);               % Used in Segmenter.filter_segments to decide the minimum size a segment should have for it to be retained.
    sp = get_param_val(sp, ep, 'filter_max_rand',       5000);              % If more segments are produced than this no., they are randomly selected and reduced to this number. Invoked by Segmenter.filter_segments().
    sp = get_param_val(sp, ep, 'graph_methods', ...
            {     'UniformGraph'     ,      'ColorGraph'       });          % A list of unary graph types to use for min-cut segmentation. These are iterated over in Segmenter.compute_segments. They are names of
                                                                            % classes of AbstractGraph type.
    sp = get_param_val(sp, ep, 'graph_sub_methods', ...
            {{'internal', 'external'}, {'internal', 'external'}});          % Each unary graph type can have slightly different sub-methods for setting unaries. Each cell lists the types of methods for each graph 
                                                                            % given in graph_methods. They are iterated over and computed from AbstractGraph.prepare_graphs(). These methods are usually listed in a 
                                                                            % switch case statement in the create_unaries() method, for instance, you can see them in ColorGraph.create_unaries().
    sp = get_param_val(sp, ep, 'graph_seed_frame_weight', ...
            {         1000           ,          1000           });          % Generally used as a scaling value for graph unaries. Each graph method has its own value. For instance, it is used by ColorGraph as a 
                                                                            % scaling constant when computing color distance metric for each superpixel (see compute_sp_*unary_values). Also used in UniformGraph*. For
                                                                            % instance a higher value in ColorGraph is likely to give smaller no. of segments with a more smaller change between the parameteric 
                                                                            % min-cuts, and the largest cut being more likely smaller in size with the same parametric lambda.
    sp = get_param_val(sp, ep, 'graph_unary_exp_scale', ...
            {          NaN           ,          0.07           });          % Only used by ColorGraph* in compute_sp_*unary_values to decide an expontial scaling for the color distance metric. This controls how 
                                                                            % similar a color should be to the seed to get a high unary value (hence more chances of lying in the fg). The quality of results from 
                                                                            % changing this value highly depends on the image itself. Each graph method has its own value.
    sp = get_param_val(sp, ep, 'graph_pairwise_contr_weight', ...
            {          1             ,            1            });          % Is the pairwise distance multiplier. It helps converting boundary value distances into a capacity value that can be used for min-cut. This
                                                                            % value is used in AbstractGraph.get_pairwise_capacities() - see comments in the file for more explanation. The effect of increasing this 
                                                                            % value is similar to <graph_pairwise_multiplier>: you are more likely to get larger segments for the same parametric lambda - hence, using
                                                                            % the same range of lambda values will also likely decrease the total number of segments when using a larger <graph_pairwise_contr_weight>.
    sp = get_param_val(sp, ep, 'graph_pairwise_potts_weight', ...
            {         1e-3           ,           4e-3          });          % This is used in conjunction with <graph_pairwise_contr_weight> to set the pairwise capacities in the graph. It acts as an offset. See 
                                                                            % AbstractGraph.get_pairwise_capacities() to find how it is exactly used. The trend in the size of segments produced when increasing its
                                                                            % value, is similar to when you increase <graph_pairwise_contr_weight>, although the change is more gradual with the same amount of increase.
    sp = get_param_val(sp, ep, 'graph_pairwise_sigma', ...
            {          1           ,             1.5           });          % This is used in conjunction with <graph_pairwise_contr_weight> and <graph_pairwise_potts_weight> in setting the pairwise capacities in the
                                                                            % graph. Its used in AbstractGraph.get_pairwise_capacities(). Increasing this value would most likely increase the number of segments
                                                                            % produced. As with other settings, each cell gives a value used for each graph method. 
    sp = get_param_val(sp, ep, 'graph_sub_methods_seeds_idx', ...
            {[     1    ,     1     ], [    2     ,     2     ]});          % Each cell in <graph_seed_gen_method> decides the seed generation method to use. This parameter gives the index to the seed generation 
                                                                            % method in <graph_seed_gen_method> to use for a particular graph method (the size of this parameter needs to be exactly the same as 
                                                                            % <graph_sub_methods>). Invoked at Segmenter.precompute_unary_data() in the precompute_seeds() function.
    sp = get_param_val(sp, ep, 'graph_seed_gen_method', ...
            {'sp_img_grid',             'sp_clr_seeds'             });      % Possible seed genereation methods used for different graph methods. The seed generation method used for a particular graph is decided by 
                                                                            % <graph_sub_methods_seeds_idx>. Invoked at Segmenter.precompute_unary_data() in the precompute_seeds() function - which generates seeds 
                                                                            % using AbstractGraph.generate_graph_seeds(). Note that if some seed method given here is not referred to in <graph_sub_methods_seeds_idx>,
                                                                            % it will never be called to generate any seeds.
    sp = get_param_val(sp, ep, 'graph_seed_nums', ...
            {    [5, 5]   ,                 [5, 5]                 });      % Indicates for each seed generation method that how many seeds should be generated. Each array indicates what's the density of seed grid on
                                                                            % the image (a [5 5] would produce a total of 25 seeds). The first number specifies the # of seeds in the vertical direction and the second in
                                                                            % the horizontal direction.
    sp = get_param_val(sp, ep, 'graph_seed_params', ...
            {  {[40, 40]} , {[15, 15], 'felzenszwalb_seeds_caller'}});      % The parameter settings for each seed generation method in <graph_seed_gen_method>. Each cell is passed as the <graph_seed_params> argument
                                                                            % in AbstractGraph.generate_graph_seeds(). For both 'sp_img_grid' and 'sp_clr_seeds', the first array is the height and width of a seed region
                                                                            % in pixels (which is then converted to a set of superpixel by generate_seeds_funcs::pixel_set_to_sp_set()). Just see 
                                                                            % AbstractGraph.generate_graph_seeds() on how different parameters are used.
%     sp = get_param_val(sp, ep, 'graph_seed_gen_method', {           'sp_seed_sampling'            });
%     sp = get_param_val(sp, ep, 'graph_seed_params',     {{64, 4, 'trained_models/train_trees.mat'}});

    
    % set miscellaneous parameters
    op = get_param_val(op, ep, 'debug', false);                             % To set debugging on. It can be invoked at different points in the program. Wherever diagnostic_methods() is called, it first determines
                                                                            % whether this option is on. If so, it proceeds with generating debug info. In set to false, it never performs any debugging tasks.
    op = get_param_val(op, ep, 'force_recompute', false);                   % Used in rigor_obj_segments() to decide whether the segments are recomputed if they are already stored on disk, i.e. if the file indicated by
                                                                            % Segmenter.return_seg_save_filepath() exists, then setting <force_recompute> to true forces recomputation of the segments.
    op = get_param_val(op, ep, 'io', false);                                % If set true, the script would not write anything to the disk. It will take the image as input and output the masks, without the additional
                                                                            % step of writing results (or intermediate results) to disk (i.e. nothing is  written in the path <data_save_dirpath>). In case results were
                                                                            % already present on disk and <force_recompute> was not on, then results could be loaded from disk and returned.
    
    
    % rest of the parameters should come from internal settings
    [sp, fp, op] = internal_params(sp, fp, op, ep);
    
    filepath_params = fp;
    segm_params = sp;
    other_params = op;
end