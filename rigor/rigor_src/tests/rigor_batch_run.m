function rigor_batch_run(SECTIONS, section_no, data_dir, gt_dir, ...
                         batchlist_filepath, file_ext, timing_ims_dir, ...
                         do_timing_analysis, varargin)
% Script that can be used to call rigor_obj_segments for a batch of a
% files with the same parameter settings. In one call to rigor_batch_run.m, 
% you can either compute segments for all the files specified, or just for 
% a subset of them (useful when parallelizing processing on a cluster). 
% You can also use the function for analyzing timing of each run of 
% rigor_obj_segments.m. The function works seamlessly for processing images 
% from the PASCAL VOC dataset.
%
% The command is as follows: 
%       rigor_batch_run(SECTIONS, section_no, data_dir, gt_dir, batchlist_filepath, file_ext, ...
%               timing_ims_dir, do_timing_analysis, varargin);
%
% For instance, if you wanted to process all the 1449 images of the PASCAL 
% VOC 2012 validation set. I am supposing that the complete dataset is 
% stored at ~/pascalvoc12: 
%     rigor_batch_run(1, 1, '~/pascalvoc12/JPEGImages', ...
%                     '~/pascalvoc12/SegmentationObject', ...
%                     '~/pascalvoc12/ImageSets/Segmentation/val.txt', ...
%                     '.jpg', '', false, 'force_recompute', true);
% This command would compute object proposals for all the validation images 
% and stores them to disk. The last two parameters forces 
% rigor_obj_segments.m to recompute all segments if some/all had been 
% computed before and stored to disk. You can also ask for generating 
% timing images in a folder, let’s say, ./outputims/ at the current 
% direction:
%     rigor_batch_run(1, 1, '~/pascalvoc12/JPEGImages', ...
%                     '~/pascalvoc12/SegmentationObject', ...
%                     '~/pascalvoc12/ImageSets/Segmentation/val.txt', ...
%                     '.jpg', 'outputims', true, 'force_recompute', true);
%
% @output:
% The main output is to disk. It generates multiple files, one for each 
% input image, containing object proposals for it. If gt_dir is not empty, 
% it also outputs one score file storing the performance compared to the 
% GT. For more details see ~/rigor_src/rigor_obj_segments.m
%
% @input:
%   SECTIONS: number of sections to divide the image set into. This is 
%       useful for dividing computation over different machines. See 
%       section_no for more info.
%
%   section_no: this number should be in the range [1, SECTIONS], and 
%       specifies which subset of images this function call has to compute. 
%       This is useful when dividing computation over different machines. 
%       If SECTIONS is set to 4, and section_no is 3, the function call 
%       would compute object proposals the 3rd quartile of images.
%
%   data_dir: the directory where the images are stored. The image 
%       filenames (without the extension) that need to be processed are in 
%       the contents of batchlist_filepath
%
%   gt_dir: the directory where GT images are stored. The corresponding GT 
%       is found by matching the filename, and replacing the extension with 
%       .png. If this path is provided, it generates the accuracy scores of 
%       all segments against the GT by calling compute_print_results.m (see
%       the file for details). If gt_dir is an empty string '', the 
%       function call doesn’t produce any scores.
%
%   batchlist_filepath: Is the path to a simple text file, where each line 
%       specifies the image’s filename (without the extension) that needs 
%       to be processed.
%
%   file_ext: The extension which would be appended to all filenames. Note 
%       that you have to specify the dot with the extension.
%
%   timing_ims_dir: If do_timing_analysis is true, this is the directory 
%       where the timing analysis images are written to.
%
%   do_timing_analysis: Boolean deciding whether to do timing analysis by 
%       invoking timing_rigor_analysis.m or not.
%
%   varargin: are the parameters that are directly passed to each call of 
%       rigor_obj_segments.m
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    if ~exist('do_timing_analysis','var')
        do_timing_analysis = true;
    end
    
    % load the filenames
    batch_files = importdata(batchlist_filepath);
    
    % RIGOR to the path
    rigor_root = fullfile(fileparts(which(mfilename)), '..');
    addpath(rigor_root);
    
    % find what files to work on
    if ~exist('SECTIONS', 'var'), SECTIONS = 1; end
    if ~exist('section_no', 'var'), section_no = 1; end
    [start_idx, end_idx] = give_section(length(batch_files), ...
        SECTIONS, section_no);
    
    if ~exist('timing_ims_dir', 'var'), timing_ims_dir = '.'; end
    
    fprintf(['WORKING ON timing_rigor_run SECTION %d out of %d: %d - ', ...
             '%d\n//////////////////////////////////////////////////', ...
             '////\n'], section_no, SECTIONS, start_idx, end_idx);
    
    seg_filepaths = {};
    scores_filepaths = {};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute cpmc for all files in the section assigned %
    for file_idx = start_idx:end_idx
        img_name = batch_files{file_idx};
        
        filepath = fullfile(data_dir, [img_name file_ext]);

        [masks, seg_obj] = rigor_obj_segments(filepath, varargin{:});
        
        % compute scores; print results; save
        if ~isempty(gt_dir)
            compute_print_results(masks, seg_obj, gt_dir);
        end
        fprintf('\n');
        
        seg_filepaths{end+1} = seg_obj.return_seg_save_filepath();
        scores_filepaths{end+1} = seg_obj.return_scores_filepath();
    end
    
    % analyze the timing info of all the calls to rigor_obj_segments
    if do_timing_analysis
        [avg_timings, avg_extra_info] = ...
            timing_rigor_analysis(seg_filepaths, timing_ims_dir);

        disp(avg_extra_info);
    end
end

function [start_idx, end_idx, section_sz] = give_section(total_len, ...
        SECTIONS, section_no)
    % get which params this program run will compute
    section_sz = ceil(total_len / SECTIONS);
    start_idx = section_sz * (section_no-1) + 1;
    end_idx = section_sz * section_no;
    if end_idx > total_len
        end_idx = total_len;
    end
    section_sz = end_idx - start_idx + 1;
end