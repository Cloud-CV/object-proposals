% Sets options for spagglom.m that are propagated through the functions. Many of the
% options are zero/one flags. The default settings were used to produce the
% results presented in the paper.


%% Superpixelation stage
opts.seg_method = 'slic'; % 'felz', 'slic' or 'qshift'. Two first recommended

% Felzenswalb superpixelation parameters
opts.felz_k = 50; % default 50
opts.felz_sigma = 0.8; % default 0.8
opts.felz_min_area = 150; % default 150

% SLIC superpixelation parameters
opts.slic_regularizer = 800; % default 800 (uses different definition than SLIC authors)
opts.slic_region_size = 20; % default 20

%% Features
opts.diagonal_connections = 0; % default 0. Whether only diagonally connected pixels are considered connected.
opts.dsift_step = 2; % default 2. calculate dsfit only every n step (quadratic speedup in n).

% Histogram features to use
opts.feature_dsift_bow = 1;    % 1 % denseSIFT bag-of-words
opts.feature_color_bow = 1;    % 2 % color bag-of-words in various color spaces
opts.feature_rgb_raw = 0;      % 3 % raw rgb histograms
opts.feature_grad_texture = 0; % 4 % feature used by van de Sande. Has two implementations, see code
opts.feature_lbp = 0;          % 6 % Local binary patterns
opts.feature_size = 1;         % 8 % size of combined superpixel
opts.features = 1:6; % This will be used in similarity.m to change histogram distances feature-wise
opts.features = opts.features(logical([opts.feature_dsift_bow, opts.feature_color_bow, opts.feature_rgb_raw, opts.feature_grad_texture, opts.feature_lbp ,opts.feature_size]));

opts.feature_weights = [1,1,2]; % default [1,1,2] with above dsift_bow, color_bow, size enabled and rest disabled

opts.collect_merged_regions = 1; % default 1. Every time a pair is merged during the greedy pairing algorithm, the new pair is saved as a region

opts.gc_branches = 15; % default 15. Number of graphcut branches.

opts.start_phase2 = 0.8; % 0.8 default. Score at which to change features and/or start branching

% Load precalculated data
opts.load_color_dict = 1; % default 1. 0 means dictionary will be created from the image (very slow). This option is used for both, rgb and lab features.
opts.load_dsift_dict = 1; % default 1. same as above but for dsift
opts.load_dsift_words = 0; % default 0. load precalculated dsift words using precalculated dict. This option overrides opts.load_dsift_dict.
opts.load_init_segs = 0; % default 0. Load initial felz or slic rgb segmentations with "default" parameters (see conditionals in code at spagglom.m)

if opts.load_dsift_dict
    load('dicts/dsift_dict_k500');
    opts.dsift_dict = dsift_dict;
    clear dsift_dict;
end


