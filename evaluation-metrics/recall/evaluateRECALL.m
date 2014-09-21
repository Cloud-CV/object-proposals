function evaluateRECALL(methods, varargin)
  if(length(varargin)>1)
		num_candidates=varargin{1};
        outputLocation = varargin{2};
  elseif(length(varargin)>0)
		num_candidates=varargin{1};
  else
        num_candidates = 1000;
  end
  
  bestRecallFileName= 'best_recall_candidates.mat';
  fh = figure;
  proposalNames = fieldnames(methods)
  n = length(proposalNames)
   
  for i=1:n
  	methods.(char(proposalNames(i))).opts.color=(randi(256,1,3)-1)./256;
  end
  
  num_pos = zeros(n, 1);
  display_auc=zeros(n,1);
  display_num_candidates=zeros(n,1);
  figure(fh); hold on; grid on;
  count = 1;
  for i = 1:n
      try
        data = load(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, bestRecallFileName)));
    
        thresh_idx = find( ...
          [data.best_candidates.candidates_threshold] <= num_candidates, 1, 'last');
        experiment = data.best_candidates(thresh_idx);
        [overlaps, recall, auc] = compute_average_recall(experiment.best_candidates.iou);
       
    display_auc(count) = auc * 100;
    % round to first decimal
    display_auc(count) = round(display_auc(count) * 10) / 10;
    display_num_candidates(count) = mean([experiment.image_statistics.num_candidates]);
    display_num_candidates(count) = round(display_num_candidates(count) * 10) / 10;
    num_pos(count) = numel(overlaps);
    line_style = '-';
    if methods.(char(proposalNames(i))).opts.isBaseline
      line_style = '--';
    end
    plot(overlaps, recall, 'Color', methods.(char(proposalNames(i))).opts.color, 'LineWidth', 1.5, 'LineStyle', line_style);
     sorted_num_candidates(count)= display_num_candidates(I(count));
     number_str = sprintf('%g (%g)', sorted_auc(count),sorted_num_candidates(count));
     label=char(methods.(char(proposalNames(i))).opts.name);
     labels{i} = sprintf('%s %s', label, number_str)
     labels{i} = number_str;
     lgnd = legend(labels, 'Location', 'NorthEast');
     catch
          fprintf('Error evaluating %s\n', (char(proposalNames(i))));
      end
  end
  
  xlabel('IoU overlap threshold');
  ylabel('recall');
  xlim([0.5, 1]);
  ylim([0, 1]);
  
  [sorted_auc,I]=sort(display_auc,'descend');

%   set(lgnd, 'color','none');
  legendshrink(0.5);
  legend boxoff;
  if(~exist(char(fullfile(outputLocation, ...
          'figures')), 'dir'))
     mkdir(char(fullfile(outputLocation, ...
         'figures')))
  end
  printpdf(char(fullfile(outputLocation, 'figures/num_candidates_recall.pdf')));
  %printpdf(sprintf('figures/num_candidates_recall.pdf'));
end
