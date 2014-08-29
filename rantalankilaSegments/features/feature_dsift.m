function [words, k] = feature_dsift(I, opts)
% Calculates SIFT descriptors on a regular grid (by default 2 pixel step),
% and clusters them into a predefined dictionary using kmeans.

Ig = single(rgb2gray(I)); % I is in rgb format regardless of colorspace argument for spagglom
[h, w] = size(Ig);

if opts.load_dsift_words
%if strcmp(opts.seg_method, 'slic')
    if strcmp(opts.image_set, 'train')
        load(sprintf('dsift500_train\\%d', opts.im_num));
    elseif strcmp(opts.image_set, 'val')
        load(sprintf('dsift500_val\\%d', opts.im_num));
    elseif strcmp(opts.image_set, 'trainval')
        load(sprintf('dsift500_trainval\\%d', opts.im_num));
    end
    
elseif opts.load_dsift_dict

    %error('You should load it above')
    %Ig = vl_imsmooth(Ig, sqrt((binSize/magnif)^2 - .25)); % dont remember
    %how using this affects results
    
    % with dict size 500, these two steps take a total of about 4 seconds.
    [locs, dsift_feat] = vl_dsift(single(Ig), 'size', 8, 'step', opts.dsift_step);
    words_mid = vl_ikmeanspush(dsift_feat, opts.dsift_dict);

    s = sub2ind([h,w], locs(2,:), locs(1,:));    
    k = size(opts.dsift_dict, 2); % number of clusters
    
    words = zeros(size(Ig),'uint16');
    words(s) = words_mid;
    words = words(:);

%     if strcmp(opts.image_set, 'train')
%         save(sprintf('dsift500_train\\%d', im_num),'words','k');
%     elseif strcmp(opts.image_set, 'val')
%         save(sprintf('dsift500_val\\%d', im_num),'words','k');
%     elseif strcmp(opts.image_set, 'trainval')
%         error('no need to save 1:200');
%     end
    
   
   
else % generate dsift dictionary for the image
    error('It is very slow to calculate dsift dictionary for each image. Use a common dictionary.'); % it should work though
    k = 10; % number of clusters
    [~, dsift_feat] = vl_dsift(single(Ig), 'size', 8); % size(f,2) = (size(I,1)-24)*(size(I,2)-24)
    
    [dsift_dict, words_mid] = vl_ikmeans(dsift_feat, k); % integer k-means clustering
    %save('car_dsift_dict', 'dsift_dict'); % create example dsift dictionary
    
    % Pad words_mid with zeros so that each pixel has a descriptor. Zeros will be ignored by histc below
    pad = 12; % depends on the size parameter of vl_dsift. size 8 gives pad 12.
    words_mid = reshape(words_mid, (size(Ig,1) - 2*pad), (size(Ig,2) - 2*pad));
    words = zeros(size(Ig),'uint8');
    words(pad+1:end-pad, pad+1:end-pad) = words_mid;
    
    % image(words) % shows that there is no indexing error
    
    words = words(:);
end

% Pad words_mid with zeros so that each pixel has a descriptor. Zeros will be ignored by histc below
% pad = 12; % depends on the size parameter of vl_dsift. size 8 gives pad 12.
% words_mid = reshape(words_mid, (size(Ig,1) - 2*pad), (size(Ig,2) - 2*pad));
% words = zeros(size(Ig),'uint8');
% words(pad+1:end-pad, pad+1:end-pad) = words_mid;
% 
% % image(words) % shows that there is no indexing error
% 
% words = words(:);


