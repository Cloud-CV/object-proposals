% This script computes recalls on VOC2012 like test_recalls.m, but it uses
% a simpler to understand method by comparing pixels directly. You can
% easily modify this script to read regions given by other methods. I have
% verified that the two recall scripts give the same results. This script is
% nowhere near as fast as test_recalls.m for the spagglom method.


%% Initialization
VOCinit;
assert(strcmp(VOCopts.dataset,'VOC2012') == 1);

spagglom_options() % load options

opts.image_set = 'val'; % 'train' = our training set, 'val' = our test set (actual validation set)

opts.get_bbox_recalls = 0; % In addition to segmentation recall scores, get bounding box scores.

% We use validation set as our test set, as there are no downloadable
% annotation available for the actual test set.
if strcmp(opts.image_set, 'train')
    images = textread(sprintf(VOCopts.seg.imgsetpath,'train'),'%s'); % 1464 images
    failset = []; %
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
seg_class_recall_count5 = zeros(1,20);
seg_class_recall_count7 = zeros(1,20);
box_class_recall_count5 = zeros(1,20);
box_class_recall_count7 = zeros(1,20);

total_regions = 0;
objects_total = 0;
class_objects_total = zeros(1,20);
%seg_class_sum = zeros(1,20);

% for converting textual class labels to numeric labels
num_cls = length(VOCopts.classes); % = 20 for VOC2007 and VOC2012
cls_to_ind = containers.Map(VOCopts.classes, 1:num_cls);

opts.profile = 0;
% opts.calculate_bounds = 1; % calculate upper bounds for segmentation recalls

if opts.profile
    profile on
end

recall_timer = tic;
for i = 1:5
%for i = setdiff(1:length(images),failset)
    if mod(i,1) == 0
        fprintf('%d ',i) % display progress
    end
    opts.im_num = i;
    
    gt = imread( sprintf(VOCopts.seg.instimgpath, char(images(i))) ); % ground truth
    [h, w] = size(gt);

    gt_ind = setdiff(unique(gt),[0, 255]); % not counting background and void
    objects_amount = length(gt_ind);
    
    im = imread( sprintf(VOCopts.imgpath, char(images(i))) ); % jpg image data
    gt_mask = logical(gt == 255); % ground truth boundaries (actually "void area")
    
    %% Get region proposals    
    orig_sp = []; % important
    region_parts = []; % important

    opts.seg_method = 'felz';
    [region_parts{1}, orig_sp{1}] = spagglom(im, opts);
    opts.seg_method = 'slic';
    [region_parts{2}, orig_sp{2}] = spagglom(im, opts);
       

    %% Convert region_parts into pixelwise regions
    regions = [];
    nrc = 0;
    for region_set = 1:length(region_parts)
        for nr = 1:length(region_parts{region_set}) % each region
            nrc = nrc + 1;
            regions{nrc} = [];
            for ps = 1:length(region_parts{region_set}{nr}) % each part of the current region
                part = region_parts{region_set}{nr}(ps);
                regions{nrc} = [regions{nrc}; orig_sp{region_set}{part}.pixels];
            end
        end
    end

    region_amount = length(regions);
    bboxes = zeros(region_amount,4);
    
    for j = 1:region_amount
        bboxes(j,:) = [min(regions{j}(:,2)) min(regions{j}(:,1)) max(regions{j}(:,2)) max(regions{j}(:,1))];
    end
    
    % Get image annotation
    im_annotation = PASreadrecord(sprintf(VOCopts.annopath, char(images(i))));
    assert(length(im_annotation.objects) == objects_amount); % images of "failset" fail this

    % Get numeric classes of objects
    classes = values(cls_to_ind, {im_annotation.objects(:).class});
    classes = cat(2, classes{:});
        
    total_regions = total_regions + region_amount;
       
    for k = 1:objects_amount
        if im_annotation.objects(k).difficult % skip

        else % not a difficult object, don't skip
            class = classes(k); 
            objects_total = objects_total + 1;
            class_objects_total(class) = class_objects_total(class) + 1;

            seg_overlap = zeros(1, region_amount);
        
            S = logical(gt == k);
            
            % Gt bounding box
            if opts.get_bbox_recalls
                X = sum(S,1);
                Y = sum(S,2);
                xmin = find(X,1,'first');
                ymin = find(Y,1,'first');
                xmax = find(X,1,'last');
                ymax = find(Y,1,'last');
            end
            
            S = S(:); % using repmat instead of looping is slower
            
            %% Segment overlap scores
            for j = 1:region_amount
                             
                R = false(h*w,1);
                
                % Using double() here is extremely important. Otherwise sub2ind below caps variable I at 65536, breaking everything.
                dreg1 = double(regions{j}(:,1));
                dreg2 = double(regions{j}(:,2));
                
                I = sub2ind([h, w], dreg1, dreg2);
                R(I) = 1;
                                                          
                int_v = sum(R & S);
                union_v = sum(R | S);
                seg_overlap(j) = int_v / union_v;
                
            end % for each region
                     
            % Select max
            [max_seg_overlap, bind] = max(seg_overlap);
                        
            %seg_class_sum(class) = seg_class_sum(class) + max_seg_overlap; % for segmentation accuracy calculations
            
            if max_seg_overlap >= 0.5
                seg_recall_count5 = seg_recall_count5 + 1;
                seg_class_recall_count5(class) = seg_class_recall_count5(class) + 1;
            end
            if max_seg_overlap >= 0.7
                seg_recall_count7 = seg_recall_count7 + 1;
                seg_class_recall_count7(class) = seg_class_recall_count7(class) + 1;               
            end

            %% Bounding box overlap scores
            if opts.get_bbox_recalls
                [max_box_overlap, bind] = max(box_overlap([xmin ymin xmax ymax], bboxes));
                
                if max_box_overlap >= 0.5
                    box_recall_count5 = box_recall_count5 + 1;
                    box_class_recall_count5(class) = box_class_recall_count5(class) + 1;
                end
                if max_box_overlap >= 0.7
                    box_recall_count7 = box_recall_count7 + 1;
                    box_class_recall_count7(class) = box_class_recall_count7(class) + 1;
                end
            end
            
        end % if not difficult
    end % for each object
        
        
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


