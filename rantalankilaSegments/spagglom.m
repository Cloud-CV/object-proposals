function [region_parts, orig_sp, varargout] = spagglom(I_rgb, opts, varargin)
% The main function for method described in "Generating object segmentation
% proposals using global and local search".
%
% INPUTS
%
%   'I_rgb' is an rgb image of type uint8
%   'opts' is an options cell array, initialized by running script
%       spagglom_options.m
%   Additionally, precalculated superpixelation for the image and/or pixel
%       features can be supplied - please see the code for details. Script
%       test_recalls.m also contains few examples.
%
% OUTPUTS
%
%   'region_parts' is a cell array, each item of which is a set of natural
%       numbers
%   'orig_sp' is a cell array. Each element represents a superpixel,
%       containing various information. The indexing corresponds to
%       region_parts. For example region_parts{1} = [4, 8] means that the
%       first region is made up of superpixels 4 and 8, which can be
%       accessed by orig_sp{4} and orig_sp{8}.
%   Additionally, histograms for each generated region proposal are
%       returned if third output variable is specified. See the very bottom
%       of this function for details.
%
%
% Requires VLFeat. Version 9.16 was used for developing.


%% Parse varargin
I_seg = [];
words = [];
histograms = [];
argl = length(varargin);
if mod(argl,2) ~= 0 % string-value pairs
    error('Give pairs of extra arguments.');
end
for argi = 0:((argl/2) - 1)
    arg_str = varargin(2*argi + 1);
    arg_val = varargin(2*argi + 2);
    switch arg_str{1}
        case 'I_seg' % Integer map of image superpixelation
            I_seg = arg_val{1};
        case 'words' % Pixelwise features
            words = arg_val{1};
        case 'histograms' % Histograms for each superpixel. Using this is not as straightforward as the above two
            histograms = arg_val{1}; 
        otherwise
            error('Argument error.');
    end
end

[h, w, ~] = size(I_rgb); % image size

opts.sp_reindexed = 0;

region_parts{1} = []; % suppresses errors if no region_parts or graphcut_parts are generated below
graphcut_parts{1} = [];

%% Initial segmentation

% Calculate the initial segmentation
[sp, K] = initial_seg(I_rgb, opts, I_seg);

orig_sp = sp; % make a copy of sp. This will be used by the scoring routine.

%% Features
if isempty(histograms) % by default, this is true
    % Compute pixel-wise features
    if isempty(words)
        [words, k] = compute_features(I_rgb, I_rgb, 'rgb', opts);
    else % use user 'words'
        k = [];
        for r = 1:length(words)
            k(r) = max(words{r}(:)); % histogram sizes
        end
    end
    
    % Compute histograms from features and add them to superpixels
    sp = compute_histograms(sp, words, k, h, w);
    
else % use user supplied histograms
    assert(length(histograms) == length(sp)); % one set of histograms for each superpixel
    hist_num = length(histograms{1});
    % Important: You must setup 'opts.features' in spagglom_options.m to
    % match what type of histograms you are supplying, in correct order.

    for r = 1:length(sp) % for each superpixel
        for fn = 1:hist_num % for each histogram
            sp{r}.hist{fn} = histograms{r}{fn}; % copy the histogram values
        end    
    end
end

%% Agglomeration of superpixels

% Calculate similarity scores between all neighboring superpixel pairs
scores = similarity_scores(sp, K, opts);


%%
%% Run the non-branching part of the algorithm. "Refining the superpixelation". <<< PHASE 1 >>>
opts.phase = 1; % Critically important line

%[sp, K, scores, region_parts_phase1] = spagglom_sub(sp, K, scores, 0, opts);
[sp, K, ~, ~] = spagglom_sub(sp, K, scores, 0, opts); % returns the current state of 'sp' and 'K'

%% Update indexing of superpixels

if 1 % update indexing for speedup. After this region_parts_primary cannot be used!
    [sp, K, scores] = update_sp_indexing(sp, K, h, w, opts); % makes rest of the algorithm (and scoring) faster by decreasing amount of parts and sp
    orig_sp = sp; % Replace the orig_sp
    opts.sp_reindexed = 1; % a note that this step was performed
else
    % Not updating the indexing allows for returning the
    % region_parts_phase1 above, because they can be represented using the
    % orig_sp defined earlier.
end


%%
%% Run the local and global search <<< PHASE 2 >>>
opts.phase = 2; % Critically important line
sp = setup_on_edge(sp, h, w); % Setup on_edge variables. Required before graphcut_regions()

graphcut_parts{1} = graphcut_regions(sp, K, opts);

initial_regions_created = 0; % default 0
[~, ~, ~, region_parts{1}] = spagglom_sub(sp, K, scores, initial_regions_created, opts); % CREATE INITIAL REGIONS HERE (YES 0 <-> 1 NO)
initial_regions_created = 1; % may prevent unnecessary duplicates if the above local search is repeated below

% Example of how to run in another color space
% [sp_nrgb, scores_nrgb] = change_color_space('nrgb', I_rgb, sp, K, im_num, h, w, [], opts);
% [~, ~, ~, region_parts{2}] = spagglom_sub(sp_nrgb, K, scores_nrgb, initial_regions_created, opts);
% graphcut_parts{2} = graphcut_regions(sp_nrgb, K, opts);


%% Combine all found regions
% Above you can collect region_parts{1}, region_parts{2}, region_parts{3}, ... as
% many as you want. You can only add region_parts_phase1 if you did NOT
% update superpixel indexing above.
%region_parts = horzcat(region_parts_phase1, region_parts{:}, graphcut_parts{:});
region_parts = horzcat(region_parts{:}, graphcut_parts{:});

%% Keep only unique entries
regions_bin = false(length(region_parts), length(orig_sp)); % Represent regions as binary masks of the superpixelation orig_sp
for ku = 1:length(region_parts)
    regions_bin(ku, region_parts{ku}) = 1;
end

% Use unique() to remove duplicates
[~, ue, ~] = unique(regions_bin, 'rows'); % This could perhaps be optimized further by summing rows of regions_bin and running unique for groups having the same sum (the same amount of parts)
region_parts = region_parts(ue); % The return value

%% Output region histograms if desired
if nargout == 3
    varargout{1} = cell(1,length(region_parts));
    for ku = 1:length(region_parts)
        varargout{1}{ku} = merge_histograms(orig_sp, region_parts{ku});
    end
    %varargout{1}{10}{2} % Example: gives the second histogram (the rgb
    % histogram in default case) of 10th region
end

