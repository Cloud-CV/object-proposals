function include_params = include_codes(segm_params, filepath_params)
%INCLUDE_CODES is used for putting codes in path according to the parameter
% settings
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    extern_dir = filepath_params.extern_src_dir;
    code_root_dir = filepath_params.code_root_dir;
    extern_codes_dir = filepath_params.extern_codes_dir;
    utils_dir = filepath_params.utils_src_dir;
    
    include_params.vlfeat_dir = fullfile(extern_dir, 'toolboxes', ...
                                         'vlfeat');
    addpath(fullfile(include_params.vlfeat_dir, 'toolbox'));
%    vl_setup;

    include_params.pb_dir = fullfile(extern_dir, ...
                                     'segmentation', 'segbench');
    
    % includes from piotr's toolbox for sketchtokens
    piotr_toolbox_dir = fullfile(extern_dir, 'toolboxes', ...
                                 'piotr_toolbox');
    
    switch segm_params.boundaries_method
        case 'Gb'
            addpath(fullfile(include_params.pb_dir, 'lib', 'matlab'));
            include_params.gb_dir = fullfile(extern_dir, ...
                                             'segmentation', ...
                'boundaries--leordeanu_ECCV_2012_gb');
            addpath(include_params.gb_dir);
            addpath(fullfile(extern_codes_dir, 'extra_gb_code'));
        case 'GPb'
            include_params.globalpb_dir = fullfile(extern_dir, ...
                                                   'segmentation', ...
                'boundaries+segments--arbelaez_PAMI_2010_bsr');
            addpath(include_params.globalpb_dir);
            addpath(fullfile(include_params.globalpb_dir, 'lib'));
        case 'Pb'        
            addpath(fullfile(include_params.pb_dir, 'lib', 'matlab'));
        case 'SketchTokens'
            include_params.sketchtokens_dir = fullfile(extern_dir, ...
                                                       'segmentation', ...
                'boundaries--lim_CVPR_2013_sketchtokens');
            addpath(include_params.sketchtokens_dir);
            
            addpath(fullfile(piotr_toolbox_dir, 'channels'));
        case 'StructEdges'
            include_params.structedges_dir = fullfile(extern_dir, ...
                                                      'segmentation', ...
                'boundaries--dollar_ICCV_2013_structedges');
            addpath(include_params.structedges_dir);
            
            addpath(fullfile(piotr_toolbox_dir, 'channels'));
        otherwise
    end
    
    % add parametric min-cut code to the path
    pmc_maxflow_method = segm_params.pmc_maxflow_method;
    if strcmp(pmc_maxflow_method, 'hochbaum')
        addpath(fullfile(extern_codes_dir, 'para_pseudoflow'));
    elseif strcmp(pmc_maxflow_method, 'kolmogorov')
        addpath(fullfile(extern_dir, ...
                'optimization/maxflow--boykov_PAMI_2004_maxflow/mex_maxflow'));
    elseif ~isempty(strfind(pmc_maxflow_method, 'nodynamic')) || ...
           ~isempty(strfind(pmc_maxflow_method, 'kohli')) || ...
           ~isempty(strfind(pmc_maxflow_method, 'multiseed'))
       addpath(fullfile(code_root_dir, 'boykov_maxflow'));
    else
    end

    addpath(filepath_params.fuxin_lib_dir);
    addpath(fullfile(filepath_params.fuxin_lib_dir, 'boosting'));
    
    % if using the seed sampler, include stuff from fuxin's library
%    if any(strcmpi(segm_params.graph_seed_gen_method, 'sp_seed_sampling'))
%        addpath(fullfile(filepath_params.fuxin_lib_dir, 'myqueue_1.1'));
%    end
   
   % only include vgg if planning to use FelzHutten superpixels
   if any(cellfun(@(x) any(strcmp(x, 'felzenszwalb_seeds_caller')), ...
          segm_params.graph_seed_params))
       addpath(fullfile(extern_dir, 'segmentation', 'imrender', 'vgg'));
   end

   addpath(fullfile(extern_dir, 'segmentation', ...
                    'stein_boundaryprocessing'));
    
   addpath(utils_dir);
   addpath(extern_dir);
    
%     % get export_fig in the path
%     addpath(fullfile(extern_dir, 'utils', 'export_fig'));
end
