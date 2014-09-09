function plot_overlap_recall_curve(methods, num_candidates, fh, ...
  names_in_plot, legend_location, use_long_labels)
  
  bestRecallFileName= 'best_recall_candidates.mat';

  if nargin < 7
    use_long_labels = false;
  end
  [~,method_order] = sort([methods.sort_key]);
  methods = methods(method_order);
  iou_file_locs ={methods.candidate_dir};
  
  labels = {methods.name};
  n = numel(iou_file_locs);
   
  n
  for i=1:n

  methods(i).color=(randi(256,1,3)-1)./256;

  end
  methods(1).color
  num_pos = zeros(n, 1);
  display_auc=zeros(n,1);
  display_num_candidates=zeros(n,1);
  figure(fh); hold on; grid on;
  for i = 1:n
    data = load([iou_file_locs{i}  bestRecallFileName]);
    thresh_idx = find( ...
      [data.best_candidates.candidates_threshold] <= num_candidates, 1, 'last');
    experiment = data.best_candidates(thresh_idx);
    [overlaps, recall, auc] = compute_average_recall(experiment.best_candidates.iou);
     
    display_auc(i) = auc * 100;
    % round to first decimal
    display_auc(i) = round(display_auc(i) * 10) / 10;
    display_num_candidates(i) = mean([experiment.image_statistics.num_candidates]);
    display_num_candidates(i) = round(display_num_candidates(i) * 10) / 10;
   %{ 
    %}
    num_pos(i) = numel(overlaps);
    line_style = '-';
    if methods(i).is_baseline
      line_style = '--';
    end
    plot(overlaps, recall, 'Color', methods(i).color, 'LineWidth', 1.5, 'LineStyle', line_style);
  end
  xlabel('IoU overlap threshold');
  ylabel('recall');
  xlim([0.5, 1]);
  ylim([0, 1]);
  
  [sorted_auc,I]=sort(display_auc,'descend');
  
  for i=1:n
     sorted_num_candidates(i)= display_num_candidates(I(i));
     number_str = sprintf('%g (%g)', sorted_auc(i),sorted_num_candidates(i));
      if names_in_plot
      label=labels{i};
      short_name=[label(1)  label(end-1) ]
      labels{i} = sprintf('%s %s', short_name, number_str);
      long_labels{i} = sprintf('%s %s', label, number_str);
    else
      labels{i} = number_str;
      long_labels{i} = number_str;
    end
  end

  if use_long_labels
    lgnd = legend(long_labels, 'Location', legend_location);
  else
    lgnd = legend(labels, 'Location', legend_location);
  end
%   set(lgnd, 'color','none');
  legendshrink(0.5);
  legend boxoff;
end
