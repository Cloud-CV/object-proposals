% Copyright (C) 2010 Joao Carreira
%
% This code is part of the extended implementation of the paper:
%
% J. Carreira, C. Sminchisescu, Constrained Parametric Min-Cuts for Automatic Object Segmentation, IEEE CVPR 2010
%
% Modified Fuxin Li 3/26/2014

function [Q, collated_scores] = SvmSegm_segment_quality(img_name, gt_dir, masks, segm_quality_type)
    if iscell(masks)
        masks = cell2mat(masks);
    end
    if ndims(masks) == 4
        if size(masks,3) > 1
            warning('foo:myCalcCandScoreFigureGroundAll', ...
                'Looking at only the first image for scoring against GT');
        end
        masks = squeeze(masks(:,:,1,:));
    end
    if strcmp(segm_quality_type,'bb_overlap')
% NOTE THIS CURRENTLY ONLY WORKS WITH VOC_STYLE ANNOTATIONS
        name = fullfile(gt_dir, [img_name '.xml']);
        rec = PASreadrecord(name);
        to_remove = [rec.objects.difficult];
        rec.objects = rec.objects(~to_remove);
        [~,all_bbox] = segment_regionprops(masks);
        all_bbox = single(all_bbox);
        for k=1:numel(rec.objects)
           box_max = bsxfun(@max, all_bbox, rec.objects(k).bbox);
           box_min = bsxfun(@min, all_bbox, rec.objects(k).bbox);
           box_int = max((box_min(:,3) - box_max(:,1)+1),0) .* max((box_min(:,4) - box_max(:,2)+1),0);
           box_uni = max((box_max(:,3) - box_min(:,1)+1),0) .* max((box_max(:,4) - box_min(:,2)+1),0);
           Q(k).q = box_int ./ box_uni;
           Q(k).gt_seg_szs = (rec.objects(k).bbox(4) - rec.objects(k).bbox(2)+1) * (rec.objects(k).bbox(3) - rec.objects(k).bbox(1)+1);
           [Q(k).best_overlap, Q(k).best_seg_idx] = max(Q(k).q);
           Q(k).extra_info.tp = box_int;
           Q(k).extra_info.fp = (all_bbox(:,4) - all_bbox(:,2) + 1) .* (all_bbox(:,3) - all_bbox(:,1) + 1) ...
                                - Q(k).extra_info.tp;
           Q(k).extra_info.fn = Q(k).gt_seg_szs - Q(k).extra_info.tp;
        end
        un = numel(rec.objects);
    else
        name = fullfile(gt_dir, [img_name '.png']);

    ground_truth_obj_segs = imread(name);

    un = unique(ground_truth_obj_segs);
    un(un==0) = [];
    un(un==255) = [];

%     care = (ground_truth_obj_segs ~= 255);
    ground_truth_k = zeros(size(ground_truth_obj_segs));
    ground_truth_k(ground_truth_obj_segs == 255) = 1;
    parfor k = 1:numel(un)
%         ground_truth_k = zeros(size(ground_truth_obj_segs));
%         ground_truth_k(ground_truth_obj_segs == un(k)) = 1;

        gt_k = ground_truth_k;
        gt_k(ground_truth_obj_segs == un(k)) = 2;
        
%         [duh1, duh2, this_Q] = myCalcCandScoreFigureGroundAll(masks,ground_truth_k, segm_quality_type, care);
        [this_Q, extra_info] = compute_error_metric(masks, gt_k, [1 2], ...
            segm_quality_type);
        Q(k).q = this_Q;
        Q(k).extra_info = extra_info;
        Q(k).gt_seg_szs = nnz(ground_truth_obj_segs == un(k));
        
        % find the best segment
        [best_overlap, best_seg_idx] = max(this_Q);
        Q(k).best_overlap = best_overlap;
        Q(k).best_seg_idx = best_seg_idx;
    end
    end
    % collate the scores (note that if the same segment was selected for a
    % particular GT, the FP would be double counted)
    total_tp = 0;
    total_union = 0;
    for k = 1:numel(un)
        best_idx = Q(k).best_seg_idx;
        total_tp = total_tp + Q(k).extra_info.tp(best_idx);
        total_union = total_union + Q(k).extra_info.fp(best_idx) + ...
            Q(k).extra_info.fn(best_idx) + Q(k).extra_info.tp(best_idx);
    end
    collated_scores.collective_overlap = total_tp / total_union;
    collated_scores.avg_best_overlap = mean([Q.best_overlap]);
    collated_scores.sz_adj_overlap = sum([Q.best_overlap] .* ...
        [Q.gt_seg_szs] ./ sum([Q.gt_seg_szs]));
end
