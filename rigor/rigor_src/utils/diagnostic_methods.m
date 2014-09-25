function [ varargout ] = diagnostic_methods( varargin )
% function for diagnostics - prints images useful for diagnosing problems
% evaluate function according to the number of inputs and outputs
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    % exit if not debug
    seg_obj = varargin{2};
    debug = seg_obj.other_params.debug;
    if debug == 0
        return;
    end
    % create debug dir if needed
    d = fullfile(seg_obj.filepath_params.debug_parent_dirpath, ...
                 seg_obj.input_info.img_name);
    if ~exist(d, 'dir')
        mkdir(d);
    end        

    % add directory to arguments
    varargin = [varargin, d];
    
    if nargout(varargin{1}) > 0
        [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
end


function print_boundaries(seg_obj, output_dir)
% prints an image showing the boundaries over the image
    imwrite(seg_obj.bndry_data.bndry_thin, ...
            fullfile(output_dir, 'se_thin.png'));
    imwrite(seg_obj.bndry_data.bndry_fat, ...
            fullfile(output_dir, 'se_fat.png'));
end


function overlay_seeds(seg_obj, seed_sets, output_filepath, output_dir)
% prints an image showing the seeds overlayed over the input image
% prints both an image with all seeds at once, and a set of images with
% each seed shown in a separate image
% run from precompute_unary_data.precompute_seeds

    output_filepath = fullfile(output_dir, output_filepath);
    
    [d,f,e] = fileparts(output_filepath);
    seeds_d = fullfile(d,f);
    if ~exist(seeds_d,'dir')
        mkdir(seeds_d);
    end
    
    if ~exist('alpha_val', 'var')
        alpha_val = 0.8;
    end
    if ~exist('alpha_bndr', 'var')
        alpha_bndr = 1;
    end
    if ~exist('dilate_bndr_sz', 'var')
        dilate_bndr_sz = 1;
    end
    
    drawFigFrames('addpath_export_fig');
    
    sz = size(seg_obj.I);
    fig_info = drawFigFrames('init_fig', sz([1 2]));
    fig_info2 = drawFigFrames('init_fig', sz([1 2]));
    
    drawFigFrames('imshow_fig', seg_obj.I, fig_info);
    drawFigFrames('holdonoff', 'on', fig_info);
    drawFigFrames('imshow_fig', seg_obj.I, fig_info2);
    drawFigFrames('holdonoff', 'on', fig_info2);
        
    alpha_mat = ones(sz([1 2])) * alpha_val;
    alpha_bndr_mat = ones(sz([1 2])) * alpha_bndr;
    gt_clr = jet(size(seed_sets,2));
    seed_im = zeros(sz);
    ech = false(sz([1 2]));
    for s = 1:size(seed_sets,2)
        m = ismember(seg_obj.sp_data.sp_seg, find(seed_sets(:,s)));
        
        curr_alpha_mat = alpha_mat;
        curr_alpha_mat(~m) = 0;

        draw_gt_im = bsxfun(@times, im2double(m), ...
                            reshape(gt_clr(s,:), [1 1 3]));
        
        drawFigFrames('image_fig', draw_gt_im, fig_info, 'AlphaData', ...
                      curr_alpha_mat);
        
        hi = drawFigFrames('image_fig', draw_gt_im, fig_info2, ...
                           'AlphaData', curr_alpha_mat);
        
        bndr = bwperim(m, 4);
        bndr = imdilate(bndr, strel('disk', dilate_bndr_sz));
        draw_bndr = im2double(repmat(bndr, [1 1 3]));

        curr_alpha_bndr_mat = alpha_bndr_mat;
        curr_alpha_bndr_mat(~bndr) = 0;

        drawFigFrames('image_fig', draw_bndr, fig_info, 'AlphaData', ...
                      curr_alpha_bndr_mat);
        
        hb = drawFigFrames('image_fig', draw_bndr, fig_info2, ...
                           'AlphaData', curr_alpha_bndr_mat);
        
        drawFigFrames('export_fig_only', ...
                      fullfile(seeds_d, sprintf('%02d',s)), fig_info2);
        
        % delete the overlays on the individual seed images
        delete([hi, hb]);
    end
    
    drawFigFrames('export_fig_and_clear', output_filepath, fig_info);
    
    drawFigFrames('close_fig', fig_info);
    drawFigFrames('close_fig', fig_info2);
end


function spseg_overlay(seg_obj, alpha_val, output_dir)
% prints an image showing the superpixels over the image
% run from precompute_im_data

    output_filepath = fullfile(output_dir, 'sp_overlay.png');
    
    if ~exist('alpha_val', 'var')
        alpha_val = 1;
    end
    
    drawFigFrames('addpath_export_fig');
    
    c = colormap(jet(seg_obj.sp_data.num_spx));
    close(gcf);
    c = c(randperm(seg_obj.sp_data.num_spx),:);
    
    sz = size(seg_obj.I);
    fig_info = drawFigFrames('init_fig', sz([1 2]));
    
    alpha_mat = ones(sz([1 2])) * alpha_val;
    
    drawFigFrames('imshow_fig', seg_obj.I, fig_info);
    drawFigFrames('holdonoff', 'on', fig_info);
    
    curr_alpha_mat = alpha_mat;
    curr_alpha_mat(:) = alpha_val;
    
    sp_im_r = zeros(sz([1 2]));
    sp_im_r(:) = c(seg_obj.sp_data.sp_seg,1);
    sp_im_g = sp_im_r;
    sp_im_g(:) = c(seg_obj.sp_data.sp_seg,2);
    sp_im_b = sp_im_r;
    sp_im_b(:) = c(seg_obj.sp_data.sp_seg,3);
    sp_im = cat(3, sp_im_r, sp_im_g, sp_im_b);
    
    drawFigFrames('image_fig', sp_im, fig_info, 'AlphaData', ...
                    curr_alpha_mat);

    drawFigFrames('export_fig_and_clear', output_filepath, fig_info);
    drawFigFrames('close_fig', fig_info);
end


function draw_unaries_all(seg_obj, abst_obj, output_dir)
% draws overlay images for each graph
% run at the end of AbstractGraph.prepare_graphs

    graph_name = class(abst_obj);

    d = fullfile(output_dir, graph_name);
    if ~exist(d, 'dir')
       mkdir(d);
    end

    ub = cumsum(abst_obj.graph_sets_per_method);
    lb = [1 ub(1:end-1)+1];

    for sub_idx = 1:length(abst_obj.graph_sub_methods)
       sub_d = fullfile(d, abst_obj.graph_sub_methods{sub_idx});
       if ~exist(sub_d, 'dir')
          mkdir(sub_d);
       end
       nonlambda_s = ...
           abst_obj.graph_unaries_all.nonlambda_s(:,lb(sub_idx):ub(sub_idx));
       nonlambda_t = ...
           abst_obj.graph_unaries_all.nonlambda_t(:,lb(sub_idx):ub(sub_idx));
       lambda_s = ...
           abst_obj.graph_unaries_all.lambda_s(:,lb(sub_idx):ub(sub_idx));
       lambda_t = ...
           abst_obj.graph_unaries_all.lambda_s(:,lb(sub_idx):ub(sub_idx));
       draw_unaries(abst_obj.seg_obj, nonlambda_s, ...
                    fullfile(sub_d, 'nonlambda_s_%04d.png'));
       draw_unaries(abst_obj.seg_obj, nonlambda_t, ...
                    fullfile(sub_d, 'nonlambda_t_%04d.png'));
       draw_unaries(abst_obj.seg_obj, lambda_s, ...
                    fullfile(sub_d, 'lambda_s_%04d.png'));
       draw_unaries(abst_obj.seg_obj, lambda_t, ...
                    fullfile(sub_d, 'lambda_t_%04d.png'));
    end
end


function draw_unaries(seg_obj, xlambda_x, output_filepattern)
% run from *Graph.generate_*_unaries

    if ~exist('alpha_val', 'var')
        alpha_val = 0.9;
    end
    if ~exist('alpha_bndr', 'var')
        alpha_bndr = 1;
    end
    if ~exist('dilate_bndr_sz', 'var')
        dilate_bndr_sz = 1;
    end
    
    drawFigFrames('addpath_export_fig');
    
    sz = size(seg_obj.I);
    fig_info = drawFigFrames('init_fig', sz([1 2]));
    
    alpha_mat = ones(sz([1 2])) * alpha_val;
    alpha_bndr_mat = ones(sz([1 2])) * alpha_bndr;
    
    for s = 1:size(xlambda_x,2)
        drawFigFrames('imshow_fig', seg_obj.I, fig_info);
        drawFigFrames('holdonoff', 'on', fig_info);

        curr_alpha_mat = alpha_mat;
        curr_alpha_mat(:) = alpha_val;

        unary_vals = xlambda_x(:,s);
        unary_vals = unary_vals(seg_obj.sp_data.sp_seg);

        drawFigFrames('imagesc_fig', unary_vals, fig_info, 'AlphaData', ...
                      curr_alpha_mat);
        colormap gray;
        
        fg_seeds = unary_vals == inf;
        
        bndr = bwperim(fg_seeds, 4);
        bndr = imdilate(bndr, strel('disk', dilate_bndr_sz));
        draw_bndr = im2double(cat(3, bndr, zeros(size(bndr)), ...
                              zeros(size(bndr))));

        curr_alpha_bndr_mat = alpha_bndr_mat;
        curr_alpha_bndr_mat(~bndr) = 0;
        
        drawFigFrames('image_fig', draw_bndr, fig_info, 'AlphaData', ...
                      curr_alpha_bndr_mat);
        
        output_filepath = sprintf(output_filepattern, s);

        drawFigFrames('export_fig_and_clear', output_filepath, fig_info);
    end
    
    drawFigFrames('close_fig', fig_info);
end


function gen_masks_overlay(seg_obj, curr_segments, ...
                           output_filepattern, output_dir)
% overlays and prints segments over the image
% run from generate_mincut_segments

    output_filepattern = fullfile(output_dir, output_filepattern);
    
    if ~exist(fileparts(output_filepattern),'dir')
        mkdir(fileparts(output_filepattern));
    end
    
    if ~exist('alpha_val', 'var')
        alpha_val = 0.7;
    end
    
    drawFigFrames('addpath_export_fig');
    
    sz = size(seg_obj.I);
    fig_info = drawFigFrames('init_fig', sz([1 2]));
    
    seg_set = curr_segments.cut_segs;

    drawFigFrames('imshow_fig', seg_obj.I, fig_info);
    drawFigFrames('holdonoff', 'on', fig_info);
    
    alpha_mat = ones(sz([1 2])) * alpha_val;
    for s = 1:size(seg_set,2)        
        m = ismember(seg_obj.sp_data.sp_seg, find(seg_set(:,s)));
        
        curr_alpha_mat = alpha_mat;
        curr_alpha_mat(:) = alpha_val;

        draw_gt_im = repmat(im2double(m), [1 1 3]);
        
        h = drawFigFrames('image_fig', draw_gt_im, fig_info, ...
                          'AlphaData', curr_alpha_mat);
        
        seed_num = curr_segments.segs_meta_info.sols_to_unary_mapping(s);
        
        curr_output_filepath = sprintf(output_filepattern, seed_num, s);
        drawFigFrames('export_fig_only', curr_output_filepath, ...
                      fig_info);
        
        delete(h);
    end
    
    drawFigFrames('close_fig', fig_info);
end