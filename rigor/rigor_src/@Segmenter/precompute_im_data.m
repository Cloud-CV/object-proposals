function precompute_im_data(seg_obj)
%PRECOMPUTE_IM_DATA precompute any info that will be used to generate
% unary or binary costs for CRF
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    % compute boundaries (and note time taken)
    bndry_filepath = return_boundaries_filepath(seg_obj);
    t_bndry = tic;
    [seg_obj.bndry_data, seg_obj.timings.extra_bndry_compute_time] = ...
        Segmenter.compute_boundaries(bndry_filepath, seg_obj.I, ...
                                     seg_obj.segm_params, ...
                                     seg_obj.other_params, ...
                                     seg_obj.preload_data);
    time_util(seg_obj, 'im_pairwise_time', t_bndry, 0, 0);
    
    % if debug, output boundaries
    diagnostic_methods('print_boundaries', seg_obj);
    
    % compute superpixels
    [seg_obj.sp_data, t_sp] = Segmenter.compute_superpixels(seg_obj.I, ...
                                seg_obj.bndry_data, seg_obj.segm_params);
    time_util(seg_obj, 'superpixels_compute_time', t_sp, 0, 1);
    
    % if debug, output superpixel image
    diagnostic_methods('spseg_overlay', seg_obj, 0.5);
    
    % precompute anything related to pairwise potentials
    % Trees seem to always help
%    if strcmp(seg_obj.segm_params.boundaries_method,'SketchTokens')
        precompute_pairwise_data_feature(seg_obj);
%    else
%       precompute_pairwise_data(seg_obj);
%    end
    
    % precompute anything related to unary potentials
    precompute_unary_data(seg_obj);
    
    time_util(seg_obj, 'total_init_time', ...
              seg_obj.timings.total_init_time, 0, 0);
end

