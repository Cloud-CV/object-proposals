function [words, k] = compute_features(I, I_rgb, I_type, opts)
% Computes the features specified in spagglom_options.m. Variable. 'words' 
% is a cell array, each cell of which is a matrix having the same size as
% the image. Matrix elements denote histogram bins, bin 0 meaning no-value.
% Output 'k' contains number of bins for each feature matrix.

% 'I' is the image in transformed format, or a duplicate of 'I_rgb',
% which must always be in RGB format. 'I_type' is a string specifying the
% format of 'I'.

features_num = 0;
k = [];
words = cell(0);

% denseSIFT with bag-of-words clustering
if opts.feature_dsift_bow
    features_num = features_num + 1;
    [words{features_num}, kt] = feature_dsift(I_rgb, opts); % dsift uses only the rgb image
    k(features_num) = kt;
end
    
% Cluster colors using k-means
if opts.feature_color_bow
    features_num = features_num + 1;
    [words{features_num}, kt] = feature_color(I, I_type, opts);
    k(features_num) = kt;
end

% Raw rgb histogram
if opts.feature_rgb_raw
    features_num = features_num + 1;
    [words{features_num}, kt] = feature_rgb_raw(I, I_type, opts);
    k(features_num) = kt;
end

% Texture feature used by van de Sande (may not be identical)
if opts.feature_grad_texture
    features_num = features_num + 1;
    [words{features_num}, kt] = feature_grad_texture2(I, opts); % This feature is calculated in three channels, so the 'words' variable unusually has size [3*h,w].
    k(features_num) = kt;
end

% Local binary patterns
if opts.feature_lbp
    features_num = features_num + 1;
    [words{features_num}, kt] = feature_lbp(I_rgb, opts); % rgb images only
    k(features_num) = kt;
end


