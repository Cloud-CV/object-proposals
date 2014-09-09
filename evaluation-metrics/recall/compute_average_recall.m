function [overlap, recall, area] = compute_average_recall(unsorted_overlaps)
  overlap = sort(unsorted_overlaps(:)', 'ascend');
  num_pos = numel(overlap);
  if max(overlap) < 1
    overlap = [0, overlap, max(overlap)+0.001];
    recall = [1, (num_pos:-1:1)/num_pos, 0];
  else
    overlap = [0, overlap];
    recall = [1, (num_pos:-1:1)/num_pos];
  end
  
%   good_overlap = overlap(overlap >= 0.5);
%   good_recall = recall(overlap >= 0.5);
  dx = overlap(2:end) - overlap(1:end-1);
  y = (recall(1:end-1) + recall(2:end)) / 2;
  area = sum(dx .* y);
end
