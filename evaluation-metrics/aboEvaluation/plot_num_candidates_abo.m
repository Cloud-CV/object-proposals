function plot_num_candidates_abo( methods, output_file_prefix)
  if nargin < 2
    output_file_prefix = '';
  end
  aboFileName= 'abo_candidates.mat';
  load('aboEvaluation/data/GtPascal2007ObjPRop.mat'); 
  abo_file_locs={methods.candidate_dir};
  labels = {methods.name};
  n = numel(abo_file_locs);
  for i=1:n
  	methods(i).color=(randi(256,1,3)-1)/256;
  end

  figure;
  for i = 1:n
    data = load([abo_file_locs{i} aboFileName]);
    num_experiments = numel(data.abo_candidates);
    x = zeros(num_experiments, 1);
    y = zeros(num_experiments, 1);
    for exp_idx = 1:num_experiments
      experiment = data.abo_candidates(exp_idx);
      [abo, ~, ~,avg_windows] = BoxAverageBestOverlap(gtBoxes,gtImageNames,experiment.candidates);
      x(exp_idx) = avg_windows;
      y(exp_idx) = abo;
    end
     label=labels{i};
    label=[label(1) label(end-1)];
    labels{i}=label;
    line_style = '-';
    if methods(i).isBaseline
      line_style = '--';
    end
    semilogx(x, y, 'Color', methods(i).color, 'LineWidth', 1.5, 'LineStyle', line_style);
    hold on; grid on;
  end
  xlim([10, 10000]);
  ylim([0 1]);
  xlabel('# candidates'); ylabel('average best overlap');
  legend(labels, 'Location', 'SouthEast');
  legendshrink(0.5);
  legend boxoff;
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(sprintf('figures/pascal/%s_average_best_overlap.pdf', output_file_prefix));
end
