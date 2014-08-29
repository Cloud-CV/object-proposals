function [n_covered,covering_boxes, covering_ids, covered_boxes, uncovered_boxes, object_ids]=computeNCoveredBoxes(ranked_boxes,ground_truth_boxes,n_windows, unique_solution,overlap_criterion)
n_g=size(ground_truth_boxes,1);
n_covered=zeros(length(n_windows),1);
n_windows=[0 n_windows];
object_ids=[];
nDets=size(ranked_boxes,1);

covering_ids=[];
covered_ids=[];
uncovered_ids=[];
if(unique_solution)
  n_windows(n_windows>nDets)=nDets;
  already_found = zeros(size(ground_truth_boxes,1),1);
  for k=2:length(n_windows)
    for i_r=(n_windows(k-1)+1):n_windows(k)
      for i_g=1:n_g
        if(~already_found(i_g))
          pascalScore = computePascalScore(ranked_boxes(i_r,:),ground_truth_boxes(i_g,:));
          if(pascalScore > overlap_criterion)
            n_covered(k-1)=n_covered(k-1)+1;
            covering_ids=[covering_ids;i_r];
            covered_ids=[covered_ids;i_g];
            already_found(i_g)=1;
          end
        end
      end
    end
  end
  object_ids=(1:size(ground_truth_boxes,1))';
else
  for k=2:length(n_windows)
    for i_r=(n_windows(k-1)+1):n_windows(k)
      for i_g=1:n_g
        pascalScore = computePascalScore(ranked_boxes(i_r,:),ground_truth_boxes(i_g,:));
        if(pascalScore > overlap_criterion)
          n_covered(k-1)=n_covered(k-1)+1;
          covering_ids=[covering_ids;i_r];
          covered_ids=[covered_ids;i_g];
          object_ids=[object_ids;i_g];
        end
      end
    end
  end
end

uncovered_ids = setxor(covered_ids,1:size(ground_truth_boxes,1));

covering_boxes=ranked_boxes(covering_ids,:);
covered_boxes=ground_truth_boxes(covered_ids,:);
uncovered_boxes=ground_truth_boxes(uncovered_ids,:);

n_covered=cumsum(n_covered);
end