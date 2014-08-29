function [words, k] = feature_color(I, I_type, opts)
% Clusters RGB values of pixels into words of a dictionary using kmeans.

I_lin = reshape(I, size(I,1)*size(I,2), 3);

if opts.load_color_dict
    % sets color_dict
    switch I_type
        case 'rgb'
            load('dicts/rgb_dict_k150');           
        case 'nrgb'
            load('dicts/nrgb_dict_k150');
        case 'opp'
            load('dicts/opp_nocut_dict_k150');
            %load('dicts/opp_dict_k150');
        case 'hsv'
            load('dicts/hsv_dict_k150');
    end
    words = vl_ikmeanspush(I_lin', color_dict);
    k = size(color_dict, 2); % number of clusters
else % generate color dictionary for the image
    error('It is recommended to load a color dictionary.');
    k = 50; % number of clusters
    [color_dict, words] = vl_ikmeans(I_lin', k); % integer k-means clustering
    %[color_dict, color_words] = vl_ikmeans(I_lin', k, 'Method', 'elkan'); % integer k-means clustering
    %save('car_color_dict', 'color_dict'); % create example color dictionary
end

words = words(:); % transpose. Using (:) instead of ' to emphasize that the words variable for each feature has the same format

% Visualize color clustering
% color_dict = uint8(color_dict); 
% Ic = color_dict(:,words')';
% Ic = reshape(Ic, size(I,1), size(I,2), 3);
% imshow(Ic);

% Shows that there is no indexing error
% words(1:20)
% words = reshape(words, size(I,1), size(I,2));
% image(words) % pixels in correct places, original image distinguishable
% words2 = words(:); % this reverses the above reshape...
% words2(1:20) % ... because this is equal to above words(1:20)