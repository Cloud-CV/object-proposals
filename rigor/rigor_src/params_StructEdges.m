function [segm_params, filepath_params, other_params] = ...
    params_StructEdges(segm_params, filepath_params, other_params, ...
                        extra_params)
% See the documentation and params_default.m
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    sp = segm_params;
    ep = extra_params;

    sp = get_param_val(sp, ep, 'pmc_maxflow_method',    'multiseed');
    sp = get_param_val(sp, ep, 'boundaries_method',     'StructEdges');
    sp = get_param_val(sp, ep, 'graph_methods',               {        'UniformGraphFuxin'          ,          'ColorGraphFuxin'           });
    sp = get_param_val(sp, ep, 'graph_sub_methods',           {{'internal', 'external', 'external2'}, {'internal', 'external', 'external2'}});
    sp = get_param_val(sp, ep, 'graph_pairwise_sigma',        {                3.5                  ,                 3.5                  });
    sp = get_param_val(sp, ep, 'graph_seed_frame_weight',     {         1000           ,          1100           });
    sp = get_param_val(sp, ep, 'graph_unary_exp_scale',       {          NaN           ,           0.5           });
    sp = get_param_val(sp, ep, 'graph_sub_methods_seeds_idx', {[     1    ,      1    ,      1     ], [    2     ,      2    ,      2     ]});
    sp = get_param_val(sp, ep, 'graph_sub_methods_cut_param', {[     1    ,      1    ,      1     ], [    1     ,      1    ,      1     ]});
    sp = get_param_val(sp, ep, 'graph_seed_gen_method',       {'sp_img_grid',       'sp_clr_seeds'         });
    sp = get_param_val(sp, ep, 'graph_seed_nums',             {      [8 8]      ,       [8 8]              });
    sp = get_param_val(sp, ep, 'graph_seed_params',           {  {[50, 50]} , {[50, 50], 'sp_seeds_caller'}});
        
    
    % rest of the parameters should come from the SketchTokens settings
    [sp, fp, op] = params_default(sp, filepath_params, ...
                                  other_params, ep);
    
    filepath_params = fp;
    segm_params = sp;
    other_params = op;
end