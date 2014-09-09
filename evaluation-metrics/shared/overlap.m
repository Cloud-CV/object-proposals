function [iou] = overlap(box, boxes)
% compute intersection over union between a single box and a set of boxes

  n_boxes = size(boxes, 1);
  iou = zeros(n_boxes, 1);

  % intersection bbox
  bi = [max(box(1),boxes(:,1)) max(box(2),boxes(:,2)) ...
    min(box(3),boxes(:,3)) min(box(4),boxes(:,4))];
  
  iw = bi(:,3) - bi(:,1) + 1;
  ih = bi(:,4) - bi(:,2) + 1;
  
  not_empty = iw > 0 & ih > 0;
  if any(not_empty)
    intersection = iw(not_empty) .* ih(not_empty);
    % compute overlap as area of intersection / area of union
    union = (boxes(not_empty,3) - boxes(not_empty,1) + 1) .* ...
         (boxes(not_empty,4) - boxes(not_empty,2) + 1) + ...
         (box(3) - box(1) + 1) * (box(4) - box(2) + 1) - ...
         intersection;
    iou(not_empty) = intersection ./ union;
  end

end