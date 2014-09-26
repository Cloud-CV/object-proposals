function evaluateABO( config,outputLocation)
  aboFileName= 'abo_candidates.mat';
  load('aboEvaluation/data/GtPascal2007ObjPRop.mat'); 
  
  proposalNames = fieldnames(config);
  n = length(proposalNames);
 count=0;  

  figure;
  for i = 1:n
      try
        data = load(char(fullfile(config.(char(proposalNames(i))).opts.outputLocation, aboFileName)));
 	count=count+1;
        num_experiments = numel(data.abo_candidates);
        x = zeros(num_experiments, 1);
        y = zeros(num_experiments, 1);
        for exp_idx = 1:num_experiments
          experiment = data.abo_candidates(exp_idx);
          [abo, ~, ~,avg_windows] = BoxAverageBestOverlap(gtBoxes,gtImageNames,experiment.candidates);
          x(exp_idx) = avg_windows;
          y(exp_idx) = abo;
        end
        label=config.(char(proposalNames(i))).opts.name;
        labels(count)=label;
        line_style = '-';
        if config.(char(proposalNames(i))).opts.isBaseline
          line_style = '--';
        end
        semilogx(x, y, 'Color', config.(char(proposalNames(i))).opts.color, 'LineWidth', 1.5, 'LineStyle', line_style);
        hold on; grid on;
      catch exc
         fprintf('Error evaluating %s\n', (char(proposalNames(i))));
      end
  end
  xlim([10, 10000]);
  ylim([0 1]);
  xlabel('# candidates'); ylabel('average best overlap');
  legend(labels{:}, 'Location', 'SouthEast');
  legendshrink(0.5);
  legend boxoff;
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  
  if(~exist(char(fullfile(outputLocation, ...
          'figures')), 'dir'))
     mkdir(char(fullfile(outputLocation, ...
         'figures')));
  end
  printpdf(char(fullfile(outputLocation, 'figures/ABO_plots.pdf')));
end
