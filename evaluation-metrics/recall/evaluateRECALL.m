function evaluateRECALL(methods, varargin)
  
  if(length(varargin)>0)
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
  
  for i = 1:n
    data = load(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, bestRecallFileName)));
    thresh_idx = find( ...
      [data.best_candidates.candidates_threshold] <= num_candidates, 1, 'last');
    experiment = data.best_candidates(thresh_idx);
    [overlaps, recall, auc] = compute_average_recall(experiment.best_candidates.iou);
     
    display_auc(i) = auc * 100;
    % round to first decimal
    display_auc(i) = round(display_auc(i) * 10) / 10;
    display_num_candidates(i) = mean([experiment.image_statistics.num_candidates]);
    display_num_candidates(i) = round(display_num_candidates(i) * 10) / 10;
    num_pos(i) = numel(overlaps);
    line_style = '-';
    if methods.(char(proposalNames(i))).opts.isBaseline
      line_style = '--';
    end
    plot(overlaps, recall, 'Color', methods.(char(proposalNames(i))).opts.color, 'LineWidth', 1.5, 'LineStyle', line_style);
  end
  
  xlabel('IoU overlap threshold');
  ylabel('recall');
  xlim([0.5, 1]);
  ylim([0, 1]);
  
  [sorted_auc,I]=sort(display_auc,'descend');
  
  for i=1:n
     sorted_num_candidates(i)= display_num_candidates(I(i));
     number_str = sprintf('%g (%g)', sorted_auc(i),sorted_num_candidates(i));
     label=char(methods.(char(proposalNames(i))).opts.name);
     labels{i} = sprintf('%s %s', label, number_str)
     labels{i} = number_str;
  end

    lgnd = legend(labels, 'Location', 'NorthEast');
%   set(lgnd, 'color','none');
  legendshrink(0.5);
  legend boxoff;
  if(~exist(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, ...
          'figures')), 'dir'))
     mkdir(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, ...
         'figures')))
  end
  printpdf(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, 'figures/num_candidates_recall.pdf')));
  %printpdf(sprintf('figures/num_candidates_recall.pdf'));
end
