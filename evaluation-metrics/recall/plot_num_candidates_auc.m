function plot_num_candidates_auc( methods, output_file_prefix)
  if nargin < 3
    output_file_prefix = '';
  end
   bestRecallFileName= 'best_recall_candidates.mat';
   
  [~,method_order] = sort([methods.sort_key]);
  methods = methods(method_order)

  iou_file_locs={methods.candidate_dir};
  labels = {methods.name};
 n=numel(iou_file_locs);
 for i=1:n
  	methods(i).color=(randi(256,1,3)-1)/256;
  end
 
  figure;
  for i = 1:n
    data = load([iou_file_locs{i}  bestRecallFileName]);
    num_experiments = numel(data.best_candidates);
    x = zeros(num_experiments, 1);
    y = zeros(num_experiments, 1);
    for exp_idx = 1:num_experiments
      experiment = data.best_candidates(exp_idx);
      [~, ~, auc] = compute_average_recall(experiment.best_candidates.iou);
      x(exp_idx) = mean([experiment.image_statistics.num_candidates]);
      y(exp_idx) = auc;
    end
    label=labels{i};
    label=[label(1) label(end-1)];
    labels{i}=label;
    line_style = '-';
    if methods(i).is_baseline
      line_style = '--';
    end
    semilogx(x, y, 'Color', methods(i).color, 'LineWidth', 1.5, 'LineStyle', line_style);
    hold on; grid on;
  end
  xlim([10, 10000]);
  ylim([0 1]);
  xlabel('# candidates'); ylabel('area under recall');
  legend(labels, 'Location', 'SouthEast');
  legendshrink(0.5);
  legend boxoff;
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(sprintf('figures/%snum_candidates_area_under_recall.pdf', output_file_prefix));

  % fixed threshold
  legend_locations = {'SouthEast', 'NorthWest', 'NorthWest'};
  thresholds = [0.5 0.7 0.8];
  for threshold_i = 1:numel(thresholds)
    threshold = thresholds(threshold_i);
    figure;
    for i = 1:n
      data = load([iou_file_locs{i}  bestRecallFileName]);
      num_experiments = numel(data.best_candidates);
      x = zeros(num_experiments, 1);
      y = zeros(num_experiments, 1);
      for exp_idx = 1:num_experiments
        experiment = data.best_candidates(exp_idx);
        recall = sum(experiment.best_candidates.iou >= threshold) / numel(experiment.best_candidates.iou);
        x(exp_idx) = mean([experiment.image_statistics.num_candidates]);
        y(exp_idx) = recall;
      end
      line_style = '-';
      if methods(i).is_baseline
        line_style = '--';
      end
      semilogx(x, y, 'Color', methods(i).color, 'LineWidth', 1.5, 'LineStyle', line_style);
      hold on; grid on;
    end
    xlim([10, 10000]);
    ylim([0 1]);
    xlabel('# candidates'); ylabel(sprintf('recall at IoU threshold %.1f', threshold));
    legend(labels, 'Location', legend_locations{threshold_i});
    legendshrink(0.5);
    legend boxoff;
%     legend(labels, 'Location', 'SouthEast');
    hei = 10;
    wid = 10;
    set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
    set(gcf, 'PaperPositionMode','auto');
    printpdf(sprintf('figures/%snum_candidates_recall_%.1f.pdf', output_file_prefix, threshold));
  end
end
