function [matching, objective] = greedy_matching_rowwise(iou_matrix)
  assert(size(iou_matrix, 1) <= size(iou_matrix, 2));
  n = size(iou_matrix, 1);
  matching = zeros(n, 1);
  objective = 0;
  for i = 1:n
    % find max element int matrix
 % [max_per_row, max_col_per_row] = max(iou_matrix, [], 2);
%       size(max_per_row)
%       size( max_col_per_row)
   [max_per_row, max_col_per_row] = max(iou_matrix')
    [max_iou,row] = max(max_per_row);
    if max_iou == -inf
      break
    end

    objective = objective + max_iou;
    col = max_col_per_row(row);
    matching(row) = col;
    iou_matrix(row,:) = -inf;
    iou_matrix(:,col) = -inf;
  end
end
