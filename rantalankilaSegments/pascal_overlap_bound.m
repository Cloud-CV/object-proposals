function [bounds, best_cover] = pascal_overlap_bound(orig_sp, sp_parts, gt, gt_ind)
%function bounds = pascal_overlap_bound(orig_sp, sp_parts, gt, gt_ind)
% Computes theoretical upper bounds of Pascal overlap score for given
% initial superpixelation sp and ground truth segmentation gt.

assert(max(gt_ind) == length(gt_ind)); % This function assumes that gt_ind = 1:n, where n >= 1.


% remove empty superpixels
% for q = length(sp):-1:1
%     if size(sp{q}.pixels,1) == 0
%         sp(q) = [];
%     end
% end
    
scores = zeros(max(gt_ind),length(sp_parts));

for i = 1:length(sp_parts) % for each sp
    %pix = double(sp{i}.pixels); % using double() here is extremely important. Otherwise sub2ind below caps variable s at 65536, breaking everything.
    %s{i} = sub2ind([h,w], pix(:,1), pix(:,2)); % linear indices of pixels of current superpixel in the image
       
    indl = 0;
    for sus = sp_parts{i}
        indl = indl + length(orig_sp{sus}.spind);
    end
    
    s{i} = zeros(1, indl);
    indl = 0;
    for sus = sp_parts{i} % for each original sp part of the current sp
        s{i}(indl+1:indl+length(orig_sp{sus}.spind)) = orig_sp{sus}.spind;
        indl = indl + length(orig_sp{sus}.spind);
    end

    sp_classes = gt(s{i}); % classes of pixels in current sp
    scores(:,i) = histc(sp_classes, gt_ind)/length(sp_classes);
   
    
end % for each superpixel

a = zeros(1, max(gt_ind)); % intersection pixel count
b = zeros(1, max(gt_ind)); % union pixel count
best_cover = [];

for ind = gt_ind % for each object
    q = find(gt == ind);
    gt_seg{ind} = q;
    b(ind) = length(q); % size of gt object, initial size of union
end

for cl = gt_ind % for each object
    [cl_scores, scoreperm] = sort(scores(cl,:), 'descend'); % cl_scores = a*/(a* + b*)
    cl_scoresx = 1./(1./cl_scores - 1); % cl_scoresx = a*/b*
    
    for i = 1:length(cl_scores)
        % condition for a/b <= (a + a*)/(b + b*) is that a/b <= a*/b*. Since
        % always a <= b, having a* >= b*, i.e., scores >= 0.5 is enough too.
        if cl_scores(i) >= 0.5 || cl_scoresx(i) >= double(a(cl))/b(cl)
            a(cl) = a(cl) + length(intersect(s{scoreperm(i)}, gt_seg{cl})); % size of intersection increases by this value
            b(cl) = b(cl) + length(setdiff(s{scoreperm(i)}, gt_seg{cl})); % size of union increases by this value
        else
            best_cover{cl} = scoreperm(1:i);
            break; % scores from now on are too low to increase the overlap ratio, stop.
        end
        
    end % for each sp
end % for each object


bounds = double(a)./b;

%toc
       

