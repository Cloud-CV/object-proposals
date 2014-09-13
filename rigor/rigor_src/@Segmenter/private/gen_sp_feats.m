function [feat, the_rest, output, sel] = gen_sp_feats(seg_obj, val, ...
                                                      match_gt)
% Generate features based on pixel-wise edge strengths 
% First get to just percentile features
%
% @authors:     Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    %num_hist = 10;
    %feat = zeros(num_hist + 2,size(edgelet_sp,1));
    % Just all the percentiles and the sum
    %counter = 1;
    output = zeros(size(seg_obj.sp_data.edgelet_sp,1),1);
    
    %the_rest = zeros(size(edgelet_sp,1),1);
    if exist('match_gt','var')
        match_gt = adjust_boundaries_sp(match_gt, seg_obj.sp_data.sp_seg);

        bndry_pairs = seg_obj.sp_data.bndry_pairs;
        
        % val can range [0, 255]
        val2 = intens_pixel_diff_mex(double(match_gt), ...
                                     uint32(bndry_pairs(:,1)), ...
                                     uint32(bndry_pairs(:,2)));
        
        output = accumarray(seg_obj.sp_data.edgelet_ids, val2);
    end
    
    [feat, sel, the_rest] = prctile_feats(val, seg_obj.sp_data.edgelet_ids);
    feat(1:10,:) = feat(1:10,:) / 255;
    feat(12,:) = feat(12,:) / 255;
    output = output(sel);
end
