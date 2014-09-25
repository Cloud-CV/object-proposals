function [masks, seg_obj, total_time] = rigor_obj_segments(img_filepath, ...
                                                           varargin)
% RIGOR_OBJ_SEGMENTS: returns multiple figure-ground segments (object 
%  proposal segments) from a single image.
%  This is a sample implementation of the ideas proposed in:
%
%   RIGOR: Reusing Inference in Graph Cuts for generating Object Regions
%   Ahmad Humayun, Fuxin Li, James M. Rehg
%   Georgia Institute of Technology
%   IEEE Conference on Computer Vision and Pattern Recognition 2014
%
%
% In its simplest form, you can just give the file path to the image, and 
% it will generate the set of masks
%     [masks] = rigor_obj_segments('peppers.png');
%
%
% @output
% The output is written to disk, unless ('io', true) (see below). The path 
% where the output is written is defined by seg_save_dirpath in 
% internal_params.m. The file stores masks, and seg_obj. These variables 
% are also directly returned by the function:
%
% masks: is a three dimensional logical matrix with the same width and 
%       height as the input image, and with the depth equal to the number 
%       of output object proposals. Hence, each slice gives a binary mask 
%       of one object proposal.
%
% seg_obj: is most of the variables stored in @Segmenter object, which 
%       includes the parameters used to generate the segments. It also 
%       stores meta_cut_segs_info, which gives information about the 
%       cuts/segments like what was the parametric lambda used for 
%       generating a cut. seg_obj also stores timings info for each graph 
%       type, and the number of segments at each stage for different graph 
%       types in num_segs.
%
% total_time: simply stores the total actual computation time. The time 
%       stored compensates for loading precomputed data from disk rather 
%       than being actually computed on spot - this time would be closer to 
%       if all processing was being done from scratch.
%
%
% @input params:
% img_filepath: is the filepath to the image that needs to be segmented. It
%       can be of any type which as long as it can be read by an be imread.
%
% varargin: is the set of string/argument pairs to override default
%       arguments. Some argument pairs:
%
%   ('params_func', <@params function>): if you don't want to use the 
%       default set of params specified in params_StructEdges, you can 
%       specify another function by giving the arguments:
%           rigor_obj_segments('im.jpg', 'params_func',@params_SketchTokens);
%       Here parameters in params_SketchTokens would be used instead of 
%       params_StructEdges. The script/function should be present in the
%       main directory. Currently the options are: @params_GB (parameters
%       tuned for running GB boundary detector [1]),  @params_SketchTokens
%       (parameters tuned for running Sketch Tokens boundary detector [2]), 
%       @params_StructEdges (parameters tuned for running Structured Edges
%       boundary detector [3]), @params_default (initial baseline set of
%       all parameters used). Also see the note about parameters below.
%
%   ([M N] OR [M]): this single 2 value array or a single value (without
%       any parameter identifying string) specifies the number of seeds to
%       enumerate for each graph type. For instance:
%           rigor_obj_segments('im.jpg', 10);
%       would generate around 10 seeds in the image, and
%           rigor_obj_segments('im.jpg', [7 3]);
%       would generate 7x3=21 seeds, for each graph type.
%
%  Also, you can change any individual parameter specified inside the
%  params_* files by first giving the string identifier (like 
%  'graph_pairwise_sigma') followed by a value (like: {10, 7}). Some
%  examples on how to change common parameters follow:
%
%   ('data_save_dirpath', '/save/path'): specifies where all the data is
%       saved including the results and the boundary detectors output.
%       
%   ('pmc_maxflow_method', METHOD_STRING): to change the graph-cut method
%       used. Possible options for METHOD_STRING are 'hochbaum'
%       (Pseudo-flow [4]), 'nodynamic' (vanilla Boykov-Kolmogorov [5]), 
%       'kohli' (Kohli-Torr dynamic graph method [6]), and finally
%       'multiseed' (our method). For additional options with 'nodynamic',
%       'kohli', and 'multiseed', see comments in
%       GraphProcessor.multiseed_param_min_st_cut().
%
%   ('pmc_num_lambdas', N): to change the number of lambdas used for 
%           parametric min-cut.
%
%   ('force_recompute', true): Recomputes the segments even if they are
%       computed and saved to file before.
%
%   ('io', true): Runs an IO only version, where nothing is written to 
%       disk. Although results might be loaded from disk if they are 
%       already present.
%
%  You can directly pass a whole structure to set a bunch of different 
%  settings. This might be more convenient in some settings where giving 
%  each parameter in the function call might become too cumbersome. There
%  are three set of parameters (you can see them in params_default.m and
%  internal_params.m):
%
%   ('segm_params', params_struct): sets the Segmenter related params. So
%       for instance you can do something like this:
%           params_struct.pmc_num_lambdas = 30;
%           params_struct.pmc_maxflow_method = 'kohli';
%           rigor_obj_segments('im.jpg', 'segm_params',params_struct);
%       which passes two parameters in the structure.
%
%   ('filepath_params', params_struct): sets filepath related params. So
%       for instance you can set parameters like this:
%           params_struct.data_save_dirpath = '/my/special/dir';
%           params_struct.extern_src_dir = '/external/src';
%           rigor_obj_segments('im.jpg', 'filepath_params',params_struct);
%
%   ('other_params', params_struct): sets miscellaneous parameters. For
%       examples you set them like this:
%           params_struct.debug = true;
%           params_struct.force_recompute = false;
%           params_struct.io = true;
%           rigor_obj_segments('im.jpg', 'other_params',params_struct);
%
%  Note, you can use any provide parameters by any combination of ways as
%  given above. For instance you can say:
%           other_struct.io = true;
%           segm_struct.graph_filter_segs = {true, false};
%           segm_struct.graph_unary_exp_scale = {NaN, 0.05};
%           fp_struct.data_save_dirpath = '/my/special/dir';
%           rigor_obj_segments('im.jpg', 100, ...
%                              'params_func',@params_SketchTokens, ...
%                              'other_params',other_struct, ...
%                              'segm_params',segm_struct, ...
%                              'filepath_params',fp_struct, ...
%                               'graph_pairwise_sigma', {5, 5});
%  Here, we used all different techniques to tell the script that you want
%  100 seeds with different parameters set by structures and by being
%  directly passed to the function as a string id/parameter pair.
%
%
% Parameter settings: Different parameter settings are defined in
%       different files. To get a detailed explanation of all the important
%       parameters have a look at params_default. Any parameter you, or the
%       params file you give, doesn't define, it is defaulted to the value
%       given in params_default. There are some additional internal
%       parameters defined in internal_params. If you don't pass any
%       parameters file as specified above, it defaults to
%       params_StructEdges. It defines a set of parameters and then calls
%       params_default at end, from which it gets all the undefined
%       parameters. If you specify the option 'params_func', it will
%       substitute params_StructEdges for defining the parameters. You can 
%       also write your own parameters file: just follow the format given 
%       in one of the params_* files and then call params_default at the 
%       end.
%
%
% [1] M. Leordeanu, et al. Efficient closed-form solution to generalized 
%     boundary detection. In ECCV, 2012.
% [2] J. Lim, et al. Sketch tokens: A learned mid-level representation for 
%     contour and object detection. In CVPR, 2013.
% [3] P. Dollar and C. Zitnick. Structured forests for fast edge detection. 
%     In ICCV,2013.
% [4] D. S. Hochbaum. The pseudoflow algorithm: A new algorithm for the
%     maximum-flow problem. Operations research, 2008.
% [5] Y. Boykov and V. Kolmogorov. An experimental comparison of min-cut/max-
%     flow algorithms for energy minimization in vision. PAMI, 2004.
% [6] P. Kohli and P. H. Torr. Dynamic graph cuts for efficient inference 
%     in markov random fields. PAMI, 2007.
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014


    % parse and divide parameters into types
    [params_func, segm_params, filepath_params, other_params, ...
        extra_params] = parse_params(varargin{:});
    % call the parameter function to populate all parameters, and override
    % ones specified by the user
    [segm_params, filepath_params, other_params] = ...
        params_func(segm_params, filepath_params, other_params, ...
                    extra_params);
    
    % read im
    input_info.img_filepath = img_filepath;
    I = imread(img_filepath);
    
    % initialize the Segmenter (include paths, init data-structures,
    % preload data, start threads ...)
    seg_obj = Segmenter(I, segm_params, filepath_params, other_params, ...
                        input_info);
    
    % where the final output will be saved to disk
    seg_save_filepath = seg_obj.return_seg_save_filepath();
    
    % run Segmenter iff not already computed, or forced to recompute
    if ~exist(seg_save_filepath, 'file') || other_params.force_recompute
        % precompute any data that can be used for unary/binary costs
        % (including boundaries, superpixels, and seed locations)
        precompute_im_data(seg_obj);

        % actual workhorse of the Segmenter: computes
        compute_segments(seg_obj);
        
        masks = seg_obj.cut_segs;
    
        clear_data(seg_obj);
        
        dir_path = fileparts(seg_save_filepath);
        % in case IO setting is off, then write result to disk
        if ~other_params.io
            if ~exist(dir_path,'dir') mkdir(dir_path); end
            save(seg_save_filepath, 'seg_obj', 'masks');
        end
    else
        fprintf('Loading segments from file %s\n', seg_save_filepath);
        load(seg_save_filepath, 'seg_obj', 'masks');
    end

    total_time = seg_obj.timings.total_seg_time;
    if ~isnan(seg_obj.timings.extra_bndry_compute_time)
        total_time = total_time + seg_obj.timings.extra_bndry_compute_time;
    end
end


function [params_func, segm_params, filepath_params, other_params, ...
            extra_params] = parse_params(varargin)
% divide the parameters from raw input varargin

    segm_params = struct;
    filepath_params = struct;
    other_params = struct;
    chosen_params = false(size(varargin));
    
    % default parameters used, if not specified by the user
    params_func = @params_StructEdges;
    
    % incase user provided number of seeds directly
    if ~isempty(varargin) && isnumeric(varargin{1})
        varargin = ['graph_seed_nums', varargin];
        chosen_params = [0 chosen_params];
    end
    
    if any(strcmpi(varargin, 'params_func'))
        param_pos = find(strcmpi(varargin, 'params_func'), 1, 'first');
        params_func = varargin{param_pos + 1};
        chosen_params([param_pos, param_pos+1]) = true;
    end
    
    if any(strcmpi(varargin, 'segm_params'))
        param_pos = find(strcmpi(varargin, 'segm_params'), 1, 'first');
        segm_params = varargin{param_pos + 1};
        chosen_params([param_pos, param_pos+1]) = true;
    end
    if any(strcmpi(varargin, 'filepath_params'))
        param_pos = find(strcmpi(varargin, 'filepath_params'), 1, 'first');
        filepath_params = varargin{param_pos + 1};
        chosen_params([param_pos, param_pos+1]) = true;
    end
    if any(strcmpi(varargin, 'other_params'))
        param_pos = find(strcmpi(varargin, 'other_params'), 1, 'first');
        other_params = varargin{param_pos + 1};
        chosen_params([param_pos, param_pos+1]) = true;
    end
    
    extra_params = varargin(~chosen_params);
end