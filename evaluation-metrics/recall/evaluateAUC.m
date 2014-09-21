function evaluateAUC( methods, varargin)
  if(length(varargin)>1)
    output_file_prefix=varargin{1};
    outputLocation = varargin{2};
  elseif(length(varargin)>0)
		output_file_prefix=varargin{1};
        outputLocation = '';
  else
        output_file_prefix = '';
        outputLocation = '';
  end
   bestRecallFileName= 'best_recall_candidates.mat';
   
 %n=length(methods);
 proposalNames = fieldnames(methods)
 n = length(proposalNames)
 
 for i=1:n
  	methods.(char(proposalNames(i))).opts.color=(randi(256,1,3)-1)/256;
 end
  count = 1;
  figure;
  for i = 1:n
      try
        data = load(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, bestRecallFileName)));
        num_experiments = numel(data.best_candidates);
        x = zeros(num_experiments, 1);
        y = zeros(num_experiments, 1);
        for exp_idx = 1:num_experiments
          experiment = data.best_candidates(exp_idx);
          [~, ~, auc] = compute_average_recall(experiment.best_candidates.iou);
          x(exp_idx) = mean([experiment.image_statistics.num_candidates]);
          y(exp_idx) = auc;
        end
        
        label=methods.(char(proposalNames(i))).opts.name;
        labels{count}=label;
        line_style = '-';
        if methods.(char(proposalNames(i))).opts.isBaseline
          line_style = '--';
        end
        semilogx(x, y, 'Color', methods.(char(proposalNames(i))).opts.color, 'LineWidth', 1.5, 'LineStyle', line_style);
        hold on; grid on;
        count = count + 1;
      catch
          fprintf('Error evaluating %s\n', (char(proposalNames(i))));
      end
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
      data = load(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation,  bestRecallFileName)));
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
      if methods.(char(proposalNames(i))).opts.isBaseline
        line_style = '--';
      end
	%labels{i} = sprintf('%s %s', label, number_str);
      semilogx(x, y, 'Color', methods.(char(proposalNames(i))).opts.color, 'LineWidth', 1.5, 'LineStyle', line_style);
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
    if(~exist(char(fullfile(outputLocation, ...
          'figures')), 'dir'))
            mkdir(char(fullfile(outputLocation, ...
         'figures')))
    end
      printpdf(char(fullfile(outputLocation, 'figures/AUC_plots.pdf')));
  end
  
end
