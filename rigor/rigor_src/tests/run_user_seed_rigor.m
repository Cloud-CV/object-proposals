% Test function demonstrating how seeds can be provided manually to
% rigor_obj_segments. In this function the seed is defined by mouse click
% on an image.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

addpath(fullfile(fileparts(which(mfilename)), '..'));

im_filepath = '/home/ahumayun/Dropbox/quals_presentation/images/2008_000960/2008_000960.jpg';
testImg = imread(im_filepath);
imshow(testImg);
seed_centers = ginput(1);
seed_centers = [seed_centers(2) seed_centers(1)];

% each row of this matrix gives a user specified seed location 
% ([row, column] format)
% seed_centers = [100 200;   300 500;   200 1];
% seed_centers = [100 200];

% this is the size of the seed region around each selected point. a [1 1] 
% just means a single pixel
seed_sz = [1 1];

% run RIGOR with user specified seeds
[masks, seg_obj, total_time] = ...
    rigor_obj_segments(im_filepath, ...
                      'graph_sub_methods_seeds_idx', {[1, 1, 1], [1, 1, 1]}, ...
                      'graph_seed_gen_method', {'gen_user_seeds'}, ...
                      'graph_seed_nums', {seed_sz}, ...
                      'graph_seed_params', {{seed_centers}}, ...
                      'force_recompute',true);

%% iterate over results and display
for idx = 1:size(masks,3)
    imshow(masks(:,:,idx));
    title(sprintf('Segment %d out of %d', idx, size(masks,3)));
    %dispMask(testImg, masks(:,:,idx), 0.1);
    hold on;
    plot(seed_centers(:,2), seed_centers(:,1), 'rx', 'MarkerSize', 10)
    pause;
end