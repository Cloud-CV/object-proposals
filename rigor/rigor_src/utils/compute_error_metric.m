function [f, extra_info] = compute_error_metric(masks, GT, params, ...
    type, gt_force_binary)
% Can compute different error measures given an output mask and a GT. It
% can also compute errors for multiple masks at the same time. The output
% is a vector of error scores of length N where N is the number of masks 
% provided.
%
% @args:
%   masks: is a logical array (size of the image) which gives the mask
%      output by an algorithm, whose overlap needs to be computed with the
%      provided ground-truth. You can provide multiple masks by
%      concatenating them on the 3rd dimension
%
%   GT: is an array (size of the image) giving the ground-truth over which 
%       all the masks are scored. GT can be of two types: (1) it can be an
%       array with only two values with one of them being zero (like a
%       logical array OR a double with 0 and 1 OR a uint8 with 0 and 128 OR
%       so on); (2) it can be an array with a range of value - in which
%       case params need to be provided to covert GT into a logical mask.
%
%   params: if in case GT is an array with a range of values, params could
%       be just a single value TH where fg = GT >= 0. It can also be a
%       vector of two values [TH1 TH2], such that GT >= TH1 & GT < TH2 is
%       ignored and fg = GT >= TH2. If GT is a logical array, you can opt
%       to provide a single value in param, telling the number of pixels 
%       around the boundary of GT which should be ignored (this should be
%       an odd number of pixels).
%
%   type (<'overlap'>, 'intersect_gt', 'centroid_displacement'): specifies
%       the type of overlap you want to compute. 'overlap' computes
%       TP/(FP+FN+TP) OR intersection/union. 'intersect_gt' computes the 
%       precision TP/(FP+TP). 'incorrect_pixels' computes FP+FN i.e. number 
%       of incorrect pixels.
%
%   gt_force_binary: if this optional parameter is true then the GT is
%       considered to be binary.

    extra_info = struct;
    
    % if GT has a third dimension, pick the first layer
    if ndims(GT) == 3
        GT = GT(:,:,1);
    end
    
    % find what sort of GT is it
    if exist('gt_force_binary', 'var') == 1 && gt_force_binary
        % if GT is binary
%         assert(any(gt_vals == 0), ...
%             'The GT provided has no background (0 values)');
        
        GT = logical(GT > 0);
        
        if exist('params','var') == 1 && ~isempty(params)
            % if don't care part is around the boundary
            assert(isscalar(params) && mod(params,2)==1, ...
                'params should be an odd scalar if GT is binary');
            
            strel_dilate = strel('disk',(params-1)/2);
            care_part = ~imdilate(bwperim(GT), strel_dilate);
        end
    else
        % if GT is not binary (threshold parameters should be provided)
        assert(exist('params','var') == 1, ...
            'params need to be given in case the GT is not binary');
        assert(isvector(params) && ismember(numel(params), [1 2]) == 1, ...
            'params should be a vector of 1 or 2 values');
        
        if numel(params) == 1
            % if threshold given
            GT(GT < params(1)) = 0;
        elseif numel(params) == 2
            care_part = ~(GT >= params(1) & GT < params(2));
            GT(GT < params(2)) = 0;
        end
        GT = logical(GT > 0);
    end

    gtcen = regionprops(GT,'Centroid');
    f = zeros(size(masks,3),1);
    % This needs memory though, decide later if it's worth it
%    masks = uint8(masks);

    % this operation would set all masks to this: 0=TN, 1=FP, FN=2, TP=3
    % (all others values are don't care)
    masks_pl_gt = bsxfun(@plus, uint8(GT) * 2, uint8(masks));
    masks_pl_gt = reshape(masks_pl_gt, size(masks_pl_gt,1) * size(masks_pl_gt,2), size(masks_pl_gt,3));
    
    if exist('care_part','var') && ~isempty(care_part)
        all_is = histc(masks_pl_gt(care_part,:), 0:3, 1);
    else
        all_is = histc(masks_pl_gt, 0:3, 1);
    end
    all_is = all_is';
    if ~exist('type','var') || isempty(type) || strcmp(type,'overlap')
        f = all_is(:,4) ./ (sum(all_is(:,2:4),2) + eps);
        extra_info.fp = all_is(:,2);
        extra_info.fn = all_is(:,3);
        extra_info.tp = all_is(:,4);
    elseif strcmp(type,'intersect_gt')
        f = all_is(:,4) ./ (all_is(:,2) + all_is(:,4) + eps);
    elseif strcmp(type,'incorrect_pixels')
        f = all_is(:,2) + all_is(:,3);
    elseif strcmp(type,'centroid_displacement')
        for i=1:size(masks,3)
            maskcen = regionprops(masks(:,:,i),'Centroid');
            gtcen = gtcen.Centroid;
            maskcen = maskcen.Centroid;
            f(i) = norm(gtcen - maskcen);
        end
    end
end