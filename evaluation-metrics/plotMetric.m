function plotMetric(configjson)

  % Plot the recall,auc abo of test set ground truth for all methods.
  %
  % This function requires the proposals to already be saved to disk. It will
  % compute a matching between ground truth and proposals (if the result is not
  % yet found on disk) and then plot recall curves. The plots are saved to
  % figures/.
  parDir = configjson.params.parDir;
  testset = load(fullfile(parDir, 'evaluation-metrics', 'data/pascal_gt_data.mat'));
  methods = getMethods(configjson);
  
  compute_best_recall_candidates(testset, methods);
  
  % compute_best_recall_candidates(testset, methods);
  %compute_abo_candidates(testset, methods);
  fh = figure;
  plot_overlap_recall_curve( methods, 100, fh, true, 'NorthEast');
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(fullfile(parDir, 'figures/pascal/recall_100_new.pdf'))
  fprintf('done 1\n');  
  
  plot_overlap_recall_curve( methods, 100, fh, true, 'NorthEast', true);
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(fullfile(parDir, 'figures/pascal/recall_100_long_names_new.pdf'))
  fprintf('done 2\n');
  
  fh = figure;
  plot_overlap_recall_curve( methods, 1000, fh, false, 'NorthEast');
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(fullfile(parDir, 'figures/pascal/recall_1000.pdf'))
  fprintf('done 3\n');  
  
  fh = figure;
  plot_overlap_recall_curve( methods, 10000, fh, false, 'SouthWest');
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(fullfile(parDir, 'figures/pascal/recall_10000.pdf'))

  plot_num_candidates_auc( methods);
  
  fprintf('printing abo..\n')
  plot_num_candidates_abo( methods);
 
end