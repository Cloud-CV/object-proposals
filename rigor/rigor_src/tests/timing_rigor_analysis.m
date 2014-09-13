function [avg_timings, avg_extra_info] = ...
    timing_rigor_analysis(seg_filepaths, output_dir, force_timing_scale)
% This function generates images to analyze the timing of each component of
% rigor_obj_segments. It breaks it down into the components in the pipeline
% (e.g. max-flow) and its sub-components (e.g. actual max-flow and its
% overheads). It generates a pipeline timing image for each image passed in
% seg_filepaths. It also generates an average image (avg_timing.eps) and a
% summary average image which collates times for sub-components 
% (avg_timing_summary.eps).
%
% The timing break-down
%   - Everything under <total_init_time> is a single time. Everything under
%     <total_computing_segs_time> are given individually for each graph
%     type. Hence, the length of the array for each field there is equal to
%     the number of graph types used.
%
%   |-- <total_seg_time>
%       |-- Setting of the segmenter
%       |-- <total_init_time> Initialize segmenter (Segmenter.initialize)
%       |   |-- <extra_bndry_compute_time> If the Pb file is loaded rather
%       |   |               than computed, this time non-zero indicating 
%       |   |               the time it took to originally compute it. 
%       |   |               NOTE: this is would be extra time actually not 
%       |   |               accounted for in the total time.
%       |   |-- <im_pairwise_time> Time for loading Pb. So the actual time
%       |   |               for computing Pb would be <im_pairwise_time> + 
%       |   |               <extra_bndry_compute_time>
%       |   |-- <superpixels_compute_time> Time taken to compute 
%       |   |               superpixels
%       |   |-- <precompute_pairwise_time> Time taken to precompute the
%       |   |               pairwise edge potentials i.e. precompute edge 
%       |   |               capacities
%       |   |-- <precompute_seed_time> Time taken to precompute the seed
%       |   |               locations and any other seed computation
%       |-- <total_computing_segs_time> Time to actually create the
%       |   |           segments (Segmenter.compute_segments)
%       |   |-- <unary_cost_set_time> Time to compute all the different
%       |   |               unary costs used for the parametric min-cut
%       |   |-- <pairwise_set_time> Time taken for setting the pairwise
%       |   |               costs in the graph (after computing Pb etc.)
%       |   |-- <pmc_time> Time to do the parametric min cut for all the
%       |   |   |           graphs created
%       |   |   |-- <pmc_parallel_cut_time> The time it takes to actually
%       |   |   |           do the cut. Note, this is done in parallel so
%       |   |   |           this time might be greater than <pmc_time>
%       |   |   |-- <pmc_parallel_overhead_time> The time it takes to set
%       |   |   |           up the graph and its values for parametric min
%       |   |   |           cut. Note, this is done in parallel so this
%       |   |   |           time might be greater than <pmc_time>
%       |   |-- <seg_filtering_time> Time to filter segments
%       |   |   |-- <init_filter_time> Time taken to initialize the segment
%       |   |   |           filteration (which includes the time to 
%       |   |   |           separate connected components)
%       |   |   |-- <energy_filter_time> Time to compute the energy for 
%       |   |   |           each segment (cut ratio), and then filtering
%       |   |   |           based on max energy
%       |   |   |-- <rand_filter_time> Time taken to randomly select
%       |   |   |           segments if more than a certain amount (based 
%       |   |   |           on segm_pars.randomize_N)
%       |   |   |-- <seg_similar_filter_time> Filtering similar segments
%       |   |   |           (this includes removing duplicate segments and
%       |   |   |           filteration based on minimum dissimilarity)
%
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    drawFigFrames('addpath_export_fig');
    
    fast_seg_root = fullfile(fileparts(which(mfilename)), '..');
    
    if ~exist('seg_filepaths', 'var') || isempty(seg_filepaths)
        seg_filepaths = {};
        sub_dir = 'data/MySegmentsMat';
        
        masks_dir = fullfile(fast_seg_root, sub_dir);
        d = dir(fullfile(masks_dir));
        for i = 1:length(d)
            if d(i).name(1) ~= '.' && d(i).isdir
                f = dir(fullfile(masks_dir, d(i).name, '*.mat'));
                seg_filepaths = ...
                    arrayfun(@(x) fullfile(masks_dir, d(i).name, x.name), ...
                             f, 'UniformOutput',false);
                if ~isempty(seg_filepaths)
                    break;
                end
            end
        end
        
        assert(~isempty(seg_filepaths), 'Cannot find any mat files');
    end
    
    if ~exist('output_dir', 'var'), output_dir = '.'; end
    if ~exist('force_timing_scale', 'var'), force_timing_scale = []; end
    
    % create directoy if non-existant
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    avg_timings = struct;
    avg_extra_info = struct;
    
    fig_info = drawFigFrames('init_fig', [420, 560], 'visible','off');
    
    all_best_overlap = [];
    
    for f_idx = 1:length(seg_filepaths)
        filepath = seg_filepaths{f_idx};
        load_mat = load(filepath);
        
        % get the extra info
        extra_info.final_num_segs = ...
            sum(load_mat.seg_obj.num_segs.after_clustering_FINAL);
        
        % get the scores data, if it was computed
        scores_fp = load_mat.seg_obj.return_scores_filepath();
        if exist(scores_fp, 'file')
            scores_mat = load(scores_fp);

            extra_info.avg_best_overlap = ...
                scores_mat.collated_scores.avg_best_overlap;
            extra_info.collective_overlap = ...
                scores_mat.collated_scores.collective_overlap;
            extra_info.mean_covering = ...
                scores_mat.collated_scores.sz_adj_overlap;
            
            all_best_overlap = [all_best_overlap, ...
                                [scores_mat.Q.best_overlap]];
        end
        
        extra_info_fields = fieldnames(extra_info);
        
        % verify the number of segments
        assert(size(load_mat.masks,3) == extra_info.final_num_segs, ...
            'Inconsistent number of segments');
        
        % sum the timing across all segmenters
        timings = load_mat.seg_obj.timings;
        timings_fields = fieldnames(timings);
        all_timings = struct;
        for idx = 1:length(timings_fields)
            all_timings.(timings_fields{idx}) = ...
                sum([timings.(timings_fields{idx})]);
        end
        
        % adjust timing if <extra_bndry_compute_time> is non-zero
        if timings.extra_bndry_compute_time > 0
            % if loaded everytime (computation for Pb was done in some 
            % other run)
            all_timings.im_pairwise_time = ...
                all_timings.im_pairwise_time + ...
                all_timings.extra_bndry_compute_time;
            all_timings.total_init_time = ...
                all_timings.total_init_time + ...
                all_timings.extra_bndry_compute_time;
            all_timings.total_seg_time = all_timings.total_seg_time + ...
                all_timings.extra_bndry_compute_time;
        end
        
        % collate the timings and the extra infos
        if f_idx == 1
            avg_timings = all_timings;
            avg_extra_info = extra_info;
        else
            for idx = 1:length(timings_fields)
                avg_timings.(timings_fields{idx}) = ...
                    avg_timings.(timings_fields{idx}) + ...
                    all_timings.(timings_fields{idx});
            end
            for idx = 1:length(extra_info_fields)
                avg_extra_info.(extra_info_fields{idx}) = ...
                    avg_extra_info.(extra_info_fields{idx}) + ...
                    extra_info.(extra_info_fields{idx});
            end
        end
        
        % draw everything in a plot
        plot_timing_bar_chart(all_timings, extra_info, ...
                              load_mat.seg_obj.input_info.img_name, ...
                              output_dir, fig_info);
        
        fprintf('Processed: %s\n', filepath);
    end
    
    % average out the timings and the extra infos
    for idx = 1:length(timings_fields)
        avg_timings.(timings_fields{idx}) = ...
            avg_timings.(timings_fields{idx}) / length(seg_filepaths);
        
    end
    for idx = 1:length(extra_info_fields)
        avg_extra_info.(extra_info_fields{idx}) = ...
            avg_extra_info.(extra_info_fields{idx}) / ...
            length(seg_filepaths);
    end

    % replace avg_best_overlap by avg best overlap per object over all
    % images
    if ~isempty(all_best_overlap)
        avg_extra_info.avg_best_overlap = mean(all_best_overlap);
    end
    
    plot_timing_bar_chart(avg_timings, avg_extra_info, 'avg', ...
                          output_dir, fig_info, 1, force_timing_scale);

    drawFigFrames('close_fig', fig_info);
end


function plot_timing_bar_chart(all_timings, extra_info, filename, ...
                               output_dir, fig_info, draw_cmprsd, ...
                               force_timing_scale)
    
    if ~exist('force_timing_scale','var') || isempty(force_timing_scale)
        force_timing_scale = [];
    end
    
    cut_prct_time = all_timings.pmc_parallel_cut_time / ...
        (all_timings.pmc_parallel_cut_time + ...
         all_timings.pmc_parallel_overhead_time);
    
    timings_str = {'Boundary compute', ...
                   'Superpixel compute', ...
                   'Pairwise precompute', ...
                   'Seeds precompute', ...
                   'Pairwise init overhead', ...
                   'Unary potential compute', ...
                   'Pairwise potential compute', ...
                   'PMC time', ...
                   'PMC overhead time', ...
                   'Segment filtering init', ...
                   'Segment energy filter', ...
                   'Segment random filter', ...
                   'Segment similar filter', ...
                   'Graph setup/PMC/Filter overhead', ...
                   'All other overheads'};
    timings_plot = [all_timings.im_pairwise_time, ...
                    all_timings.superpixels_compute_time, ...
                    all_timings.precompute_pairwise_time, ...
                    all_timings.precompute_seed_time, ...
                    all_timings.total_init_time - ...
                        (all_timings.im_pairwise_time + ...
                         all_timings.superpixels_compute_time + ...
                         all_timings.precompute_pairwise_time + ...
                         all_timings.precompute_seed_time), ...
                    all_timings.unary_cost_set_time, ...
                    all_timings.pairwise_set_time, ...
                    all_timings.pmc_time * cut_prct_time, ...
                    all_timings.pmc_time * (1-cut_prct_time), ...
                    all_timings.init_filter_time ...
                    all_timings.energy_filter_time, ...
                    all_timings.rand_filter_time, ...
                    all_timings.seg_similar_filter_time, ...
                    all_timings.total_computing_segs_time - ...
                        (all_timings.unary_cost_set_time + ...
                         all_timings.pairwise_set_time + ...
                         all_timings.pmc_time + ...
                         all_timings.init_filter_time + ...
                         all_timings.energy_filter_time + ...
                         all_timings.rand_filter_time + ...
                         all_timings.seg_similar_filter_time), ...
                    all_timings.total_seg_time - ...
                        (all_timings.total_init_time + ...
                         all_timings.total_computing_segs_time)];
    color_ids = [1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 5];
    clrs = [0.7 0.3 0; 0.2 0.2 0.8; 0.2 0.8 0.2; 0.2 0.6 0.6; 0.5 0.5 0.5];
    
    header_txts = {};
    
    header_txts{end+1} = sprintf('Total time: %.3fs', ...
                                all_timings.total_seg_time);
    if isfield(extra_info, 'avg_best_overlap')
        header_txts{end+1} = sprintf(['Total num segs.: %d\n', ...
                                  'Mean best overlap: %.4f\n', ...
                                  'Mean best covering: %.4f'], ...
                                 round(extra_info.final_num_segs), ...
                                 extra_info.avg_best_overlap, ...
                                 extra_info.mean_covering);
    else
        header_txts{end+1} = sprintf(['Total num segs.: %d\n'], ...
                                 round(extra_info.final_num_segs));
    end
    header_font_szs = [12, 8];
    
%     out_filepath = fullfile(output_dir, [filename, '_timing.png']);
    out_filepath = fullfile(output_dir, [filename, '_timing.eps']);
    
    plot_print_bar(fig_info, timings_plot, timings_str, clrs, ...
                   color_ids, header_txts, header_font_szs, ...
                   out_filepath, force_timing_scale);
    
    if exist('draw_cmprsd','var') && draw_cmprsd == 1
        cmprsd_timings_str = {'Boundary compute', ...
                              'Superpixel compute', ...
                              'Pairwise compute', ...
                              'Unary compute', ...
                              'Parametric min-cut', ...
                              'Segment filteration', ...
                              'Overheads'};
        color_ids = [1, 1, 2, 2, 3, 4, 5];
    
        mapping = [1, 2, 3, 4, 3, 4, 3, 5, 5, 6, 6, 6, 6, 7, 7]';
        cmprsd_timings_plot = accumarray(mapping, timings_plot')';
        
        out_filepath = fullfile(output_dir, ...
                                [filename, '_timing_summary.eps']);
        
        plot_print_bar(fig_info, cmprsd_timings_plot, ...
                       cmprsd_timings_str, clrs, ...
                       color_ids, header_txts, header_font_szs, ...
                       out_filepath, force_timing_scale)
    end
end


function plot_print_bar(fig_info, timings_plot, timings_str, clrs, ...
                        color_ids, header_txts, header_font_szs, ...
                        filepath, force_timing_scale)
    fig_h = drawFigFrames('get_fig_h', fig_info);
    ax_h = drawFigFrames('get_ax_h', fig_info);
    
    N = length(timings_plot);
    
    for i = 1:N
        h = bar(ax_h, i, timings_plot(i));
        if i == 1, hold(ax_h, 'on'); end
        set(h, 'FaceColor', clrs(color_ids(i),:));
    end
    
    if exist('force_timing_scale','var') && ~isempty(force_timing_scale)
        ylim(ax_h, force_timing_scale);
    end
    
    ypos = -max(ylim)/50;
    text(1:N, repmat(ypos,N,1), ...
         timings_str','HorizontalAlignment','Right','Rotation',90, ...
         'FontSize',10, 'Parent',ax_h)
    ylabel(ax_h, 'computation time (secs)','FontSize',12);
    
    pos = get(ax_h, 'Position');
    set(ax_h, 'Position', [pos(1) 0.45 pos(3) 0.53]);
    
    extra_txt_pos = [max(xlim(ax_h)) - (max(xlim(ax_h))/20), ...
                     max(ylim(ax_h)) - (max(ylim(ax_h))/20)];
    
    for h_idx = 1:length(header_txts)
        text(extra_txt_pos(1), extra_txt_pos(2) - ((h_idx-1) * max(ylim)/12), ...
             header_txts{h_idx}, 'HorizontalAlignment','Right', ...
             'VerticalAlignment','Top', 'FontSize', ...
             header_font_szs(h_idx), 'Parent',ax_h);
    end
    
%     export_fig(filepath, '-a1', '-transparent', fig_h);
%     saveas(fig_h, filepath);
    print(fig_h, filepath, '-depsc2');
    
    delete(get(ax_h, 'children'));
end
