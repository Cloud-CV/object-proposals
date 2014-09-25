function [segm_params, filepath_params, other_params] = ...
        internal_params(segm_params, filepath_params, other_params, ...
                       extra_params)
% the internal parameters which are not usually of severe importance to a
% practictioner. Nevertheless, feel free to tinker if you know what you are
% doing :)
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014
    
    fp = filepath_params;                                                   % Parameters related to directory locations
    sp = segm_params;                                                       % Parameters for FastSeg's technical internals
    op = other_params;                                                      % Misc. parameters
    ep = extra_params;                                                      % Params passed as an argument for overriding parameters here
    
    
    % set the filepath parameters
    fp = get_param_val(fp, ep, 'extern_src_dir', ...
                           fullfile(fp.code_root_dir, 'extern_src'));       % External dependencies directory
    fp = get_param_val(fp, ep, 'fuxin_lib_dir', ...
                           fullfile(fp.code_root_dir, 'extern_src/fuxin_lib_src'));    % External dependencies to Fuxin's library
    fp = get_param_val(fp, ep, 'extern_codes_dir', ...
                           fullfile(fp.code_root_dir, 'extern_src'));       % External dependencies packaged with this code
    fp = get_param_val(fp, ep, 'utils_src_dir', ...
                           fullfile(fp.code_root_dir, 'utils'));            % Directory to our utility functions
    fp = get_param_val(fp, ep, 'seg_save_dirpath', ...
                           fullfile(fp.data_save_dirpath, 'MySegmentsMat'));% Directory where segments computed (results) are saved
   fp = get_param_val(fp, ep, 'trained_models_dirpath', ...
                           fullfile(fp.code_root_dir, 'trained_models'));   % All the trained models (for instance, for boundary energies) reside in this directory
    fp = get_param_val(fp, ep, 'scores_dirpath', ...
                           fullfile(fp.seg_save_dirpath, 'scores'));        % Used by compute_print_results() to save quantitative results for the segments computed
    fp = get_param_val(fp, ep, 'boundaries_parent_dirpath', ...
                           fp.data_save_dirpath);                           % The main directory where boundary detection results are saved
    fp = get_param_val(fp, ep, 'debug_parent_dirpath', ...
                           fullfile(fp.data_save_dirpath, 'Debug'));        % Where any debug information is output (usually when other_params.debug = true)
    
    
    % set the Segmenter parameters
    sp = get_param_val(sp, ep, 'bg_frame_width',        1);                 % Decides the no. of pixels to use at the boundary, which is then used to generate the bg seed. A large number would force more superpixels 
                                                                            % to be used background seeds. Invoked at Segmenter.precompute_unary_data().
    sp = get_param_val(sp, ep, 'filter_max_energy',     5000);              % Threshold used by Segmenter.filter_segments to filter segments with too high of a cut ratio. The energy is computed in compute_energies().
    sp = get_param_val(sp, ep, 'graph_pairwise_multiplier', ...
            {         1000           ,          1000           });          % Used in AbstractGraph.set_pairwise_graph() as a scaling factor for all pairwise capacities. A larger value will increase pairwise 
                                                                            % capacities and hence increase the likelihood for larger segments. Each cell gives a value used for each graph method. 
    sp = get_param_val(sp, ep, 'graph_sub_methods_cut_param', ...
            {[     1    ,     1     ], [    1     ,     1     ]});          % For graph-cut settings. Invoked in GraphProcessor.multiseed_param_min_st_cut() as <graphcut_params>. A 0 value here would schedule
                                                                            % parametric lambdas in reverse i.e. if you have lambda values of 0,1,2,5 for paramertic min-cut, a 0 parameter here would compute min-cuts
                                                                            % in the order 5,2,1,0. A parameter 1 schedules it in the normal ascending direction. Both methods give the same results but might effect the
                                                                            % computation time. This can possibly be extended to support other parameter settings for graph-cuts.
    sp = get_param_val(sp, ep, 'graph_filter_segs', ...
            {         true           ,           true          });          % Indicates whether you want to filter the segments produced by a particular graph method. Invoked in Segmenter.filter_segments().
    sp = get_param_val(sp, ep, 'graph_sol_upper_bp', ...
            [         20             ,           300           ]);          % Decides the upper limit for the lambdas used for the parameteric min-cut. This is the <u> value in GraphProcessor.generate_param_lambdas()
                                                                            % See the function to find the exact algorithm used to generate the list of lambdas for parametric min-cut.
    
    
    % set miscellaneous parameters
    hash_params.Format = 'base64';
    hash_params.Method = 'SHA-1';
    op = get_param_val(op, ep, 'hash_params', hash_params);                 % Hashing parameters. This is used to create a hash of the settings used - this is useful for figuring out if the same set of parameters were
                                                                            % used for computing a set of segments, without comparing the parameters directly.
    
    % compute the hash for the parameters (acts as a unique ID for params)
%     addpath(fullfile(fp.extern_codes_dir, 'DataHash'));
%     op.filepath_params_hash = DataHash(fp, hash_params);
%     op.segm_params_hash = DataHash(sp, hash_params);
    op.filepath_params_hash = num2str(sum(getByteStreamFromArray(fp)));
    op.segm_params_hash = num2str(sum(getByteStreamFromArray(sp)));
    
    filepath_params = fp;
    segm_params = sp;
    other_params = op;
end

