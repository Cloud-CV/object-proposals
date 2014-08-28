% Computes recalls on VOC2012 segmentation task data set using
% thresholds 0.5 and 0.7, and using both generated segments and their
% bounding boxes.
% This version is works with our method only, as it uses superpixels for calculations.

%% Initialization
VOCinit; % be sure to add path for the VOC2012 data
assert(strcmp(VOCopts.dataset,'VOC2012') == 1);

method = 'spagglom';
opts.profile = 0; % Use matlab profiler. May not correctly measure time spent on this function

spagglom_options() % load options variable 'opts'

opts.image_set = 'val'; % 'train' = our training set, 'val' = our test set (actual validation set)

opts.get_bbox_recalls = 0; % In addition to segmentation recall scores, get bounding box scores.

addpath('features');
addpath('dicts');

% We use validation set as our test set, as there are no downloadable
% annotation available for the actual test set.
if strcmp(opts.image_set, 'train')
    images = textread(sprintf(VOCopts.seg.imgsetpath,'train'),'%s'); % 1464 images
    failset = [];
elseif strcmp(opts.image_set, 'val')
    images = textread(sprintf(VOCopts.seg.imgsetpath,'val'),'%s'); % 1449 images
    failset = [532, 666, 917, 1418, 1426]; % These images seem to have problems with their annotation. I'm just skipping them.
elseif strcmp(opts.image_set, 'trainval')
    images = textread(sprintf(VOCopts.seg.imgsetpath,'trainval'),'%s'); % 1464 + 1449 images (?) 
    failset = [1074, 1325, 1843, 1856, 2851, 2869];
end

seg_recall_count5 = 0; % for threshold 0.5
seg_recall_count7 = 0; % for threshold 0.7
box_recall_count5 = 0; % for threshold 0.5
box_recall_count7 = 0; % for threshold 0.7
seg_class_recall_count7 = zeros(1,20);

class_objects_total = zeros(1,20);
total_regions = 0;
objects_total = 0;
bboxes = [];

sp_amount = 0;

% for converting textual class labels to numeric labels
num_cls = length(VOCopts.classes); % = 20 for VOC2007 and VOC2012
cls_to_ind = containers.Map(VOCopts.classes, 1:num_cls);

if opts.profile
    profile on
end

recall_timer = tic;
%for i = 1:5 % run part of the dataset
for i = setdiff(1:length(images),failset) % Use this to run the whole dataset
    if mod(i,1) == 0
        fprintf('%d ',i) % display progress
    end  
    opts.im_num = i;
    
    gt = imread( sprintf(VOCopts.seg.instimgpath, char(images(i))) ); % ground truth
    [h, w] = size(gt); % image size

    gt_ind = setdiff(unique(gt),[0, 255]); % not counting background and void
    objects_amount = length(gt_ind);
    
    im = imread( sprintf(VOCopts.imgpath, char(images(i))) ); % jpg image data          
    gt_mask = logical(gt == 255); % ground truth boundaries (actually "void area")
    
    %% Get region proposals    
    orig_sp = []; % important
    region_parts = []; % important

    % Get segmentations using the method. These next 4 lines correspond to
    % the major results presented in the paper. Different points on the
    % curves are obtained by adjusting the parameter opts.gc_branches,
    % which is by default 15 (gives the first high points on the three curves).
    opts.seg_method = 'felz';
    [region_parts{1}, orig_sp{1}] = spagglom(im, opts);
    opts.seg_method = 'slic';
    [region_parts{2}, orig_sp{2}] = spagglom(im, opts);
    
    % Other examples of use:
    % [region_parts{2}, orig_sp{2}] = spagglom(im, opts,'I_seg',Is_int,'words',words);
    % [region_parts{2}, orig_sp{2}] = spagglom(im, opts,'I_seg',Is_int);
    % [region_parts{2}, orig_sp{2}, histograms] = spagglom(im, opts);
    
    region_amount = length(region_parts{1});
    
    % Transform pixel coordinates to indices
    for region_set = 1:length(region_parts)
        for sus = 1:length(orig_sp{region_set})
            orig_sp{region_set}{sus}.spind = sub2ind([h,w], double(orig_sp{region_set}{sus}.pixels(:,1)), double(orig_sp{region_set}{sus}.pixels(:,2)));
        end  
    end
    
    sp_amount = sp_amount + length(orig_sp{1}); % not updated to multiple {region_set}
      
    
    if opts.get_bbox_recalls
        % For each sp of orig_sp, find its bounding box
        for region_set = 1:length(region_parts)
            sp_edges{region_set} = zeros(length(orig_sp{region_set}), 4);
            bboxes{region_set} = zeros(length(region_parts{region_set}), 4);
            
            % find edges of Ri
            for ses = 1:length(orig_sp{region_set})
                Ri = false(h, w); % note ',', not '*' as below
                Ri(orig_sp{region_set}{ses}.spind) = 1;
                Xi = sum(Ri,1);
                Yi = sum(Ri,2);
                sp_edges{region_set}(ses,:) = [find(Xi,1,'first'), find(Yi,1,'first'), find(Xi,1,'last'), find(Yi,1,'last')];               
            end
            
            % Using the above bounding boxes, solve bounding box of each region
            % proposal
            for j = 1:length(region_parts{region_set})
                sus = region_parts{region_set}{j};
                if ~isempty(sus)
                    tg = sp_edges{region_set}(sus,:);
                    bboxes{region_set}(j,:) = [min(tg(:,1)), min(tg(:,2)), max(tg(:,3)), max(tg(:,4))]; % bounding box is the most extreme values of individual bounding boxes
                else
                    bboxes = [];
                end
            end
        end % for each region set
    end % if opts.get_bbox_recalls
    
    %%
    
    % Get image annotation
    im_annotation = PASreadrecord(sprintf(VOCopts.annopath, char(images(i))));
    %assert(length(im_annotation.objects) == objects_amount); % images of "failset" fail this
    
    if length(im_annotation.objects) ~= objects_amount
        warning('Problems with annotation');
        continue; % skip this image!
    end
    
    % Get numeric classes of objects
    classes = values(cls_to_ind, {im_annotation.objects(:).class});
    classes = cat(2, classes{:});
    
    % count region proposals
    for region_set = 1:length(region_parts)
        total_regions = total_regions + length(region_parts{region_set});
    end
    
    found_obj{i} = zeros(1, objects_amount);
    
    for k = 1:objects_amount
        if im_annotation.objects(k).difficult % skip

        else % not a difficult object, don't skip
            class = classes(k);          
            objects_total = objects_total + 1;
            class_objects_total(class) = class_objects_total(class) + 1;
            
            seg_overlap = zeros(1, 0);
            
            S = logical(gt == k); % alt 2
            
            if opts.get_bbox_recalls

                X = sum(S,1);
                Y = sum(S,2);
                xmin = find(X,1,'first');
                ymin = find(Y,1,'first');
                xmax = find(X,1,'last');
                ymax = find(Y,1,'last');
                
                for region_set = 1:length(region_parts)
                    [max_box_overlap(region_set), ~] = max(box_overlap([xmin ymin xmax ymax], bboxes{region_set}));
                end
                max_box_overlap = max(max_box_overlap); % pick best among all region sets
                
                if max_box_overlap >= 0.5
                    box_recall_count5 = box_recall_count5 + 1;
                end
                if max_box_overlap >= 0.7
                    box_recall_count7 = box_recall_count7 + 1;
                    
                end
            end
                       
            S = S(:); % using repmat instead of looping is slower
                     
            %% Segment overlap scores
            
            for region_set = 1:length(region_parts)
                int_term   = zeros(1, length(orig_sp{region_set}));
                union_term = zeros(1, length(orig_sp{region_set}));
                for ses = 1:length(orig_sp{region_set})
                    Ri = false(h*w,1);
                    Ri(orig_sp{region_set}{ses}.spind) = 1;
                    int_term(ses) = sum(Ri & S);    % Ri and S
                    union_term(ses) = sum(Ri & ~S); % Ri minus S

                end
                S_size = sum(S);
                              
                for j = 1:length(region_parts{region_set})                  
                        sp_list = region_parts{region_set}{j};
                        int_v = sum(int_term(sp_list));
                        union_v = sum(union_term(sp_list)) + S_size;
                        
                        seg_overlap(end+1) = int_v / union_v;                              
                end % for each region
            end % for each region_set
            
            % Select max
            [max_seg_overlap, bind] = max(seg_overlap);
              
            if max_seg_overlap >= 0.5
                seg_recall_count5 = seg_recall_count5 + 1;
            end
            if max_seg_overlap >= 0.7
                seg_recall_count7 = seg_recall_count7 + 1;
                seg_class_recall_count7(class) = seg_class_recall_count7(class) + 1;
            end
                     
        end % if not difficult
    end % for each object
    
    %save(sprintf('sp_at_branching_point/gt%d.mat',i),'gt','gt_bin')
         
    opts.record_movie = 0; % so that you don't accidentally display multiple movies     
end % for each image
fprintf('\n')
toc(recall_timer)

if i == length(images)
    avg_regions = total_regions/(length(images) - length(failset));
else
    avg_regions = total_regions/i; % i will have the last value
end

%% Compute final recalls
seg_pooled_recall5 = seg_recall_count5/objects_total;
seg_pooled_recall7 = seg_recall_count7/objects_total;
if opts.get_bbox_recalls
    box_pooled_recall5 = box_recall_count5/objects_total;
    box_pooled_recall7 = box_recall_count7/objects_total;
end

fprintf('avg regions:    %f\n', avg_regions);
fprintf('seg_pool 0.5:   %f\n', seg_pooled_recall5);
fprintf('seg_pool 0.7:   %f\n', seg_pooled_recall7);
if opts.get_bbox_recalls
    fprintf('box_pool 0.5:   %f\n', box_pooled_recall5);
    fprintf('box_pool 0.7:   %f\n', box_pooled_recall7);
end

if opts.profile
    profile off
    profile report
end

