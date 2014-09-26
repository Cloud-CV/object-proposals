function evaluateRECALL(methods, outputLocation,varargin)
  bestRecallFileName= 'best_recall_candidates.mat';
  fh = figure;
  proposalNames = fieldnames(methods);
  n = length(proposalNames);
  
  defaultNumCandidates=1000;
  if(length(varargin)>0)
	num_candidates=varargin{1};
  else
	num_candidates=defaultNumCandidates;  
  end
  num_pos = zeros(n, 1);
  display_auc=[];
  display_num_candidates=[];
  number_str=[];
  labels=cell(0,0);
  sorted_labels=cell(0,0);
  figure(fh); hold on; grid on;
  count = 0;
  for i = 1:n
      try
        data = load(char(fullfile(methods.(char(proposalNames(i))).opts.outputLocation, bestRecallFileName)));
    	count=count+1;
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
     	number_str{count} = sprintf('%g (%g)', display_auc(count),display_num_candidates(count));
     	label=char(methods.(char(proposalNames(i))).opts.name);
	sprintf('%s %s', label, number_str{count});
     	labels{count} = sprintf('%s %s', label, number_str{count});
     catch exc
          fprintf('Error evaluating %s\n', (char(proposalNames(i))));
	  msg = exc.message;
	  fprintf(msg);
	  fprintf('\n****  Continuing ..****\n');
      end
  end
  xlabel(sprintf('IoU overlap threshold @ %d',num_candidates));
  ylabel('recall');
  xlim([0.5, 1]);
  ylim([0, 1]);
  [sorted_auc,I]=sort(display_auc,'descend');
  for i=1:count
 	sorted_labels(i)=labels(I(i));
  end	
 
  lgnd = legend(sorted_labels{:}, 'Location', 'NorthEast');
  legendshrink(0.5);
  legend boxoff;
  if(~exist(char(fullfile(outputLocation, ...
          'figures')), 'dir'))
     mkdir(char(fullfile(outputLocation, ...
         'figures')));
  end
  plotFile=sprintf('figures/%d_proposals_recall.pdf',num_candidates);
  printpdf(char(fullfile(outputLocation, plotFile)));
  fprintf('Plot saved to : %s\n',char(fullfile(outputLocation, plotFile)));
end
