function recall_compute_candidates_voc07(method_configs, images)
  % Run proposal methods over the pascal test set.
  %   method_configs  are the configs of the methods you want to run, as
  %                   provided by get_method_configs()
  %   images          the pascal image IDs to run on
  %
  % This method checks is the candidate detections are already there and only
  % computes candidates if they are not found.
  num_candidates = 10000;
  
  if nargin < 1
    % default to running all methods
    method_configs = get_method_configs();
  end
  if nargin < 2
    % default to running on the full test set
    testset = load('data/pascal_voc07_test_annotations.mat');
    images = {testset.impos.im};
    clear testset;
  end
  
  % seed to milliseconds
  seed = str2double(datestr(now,'HHMMSSFFF'));
  rng(seed);

  num_iterations = numel(images) * numel(method_configs);
  for im_i = 1:numel(images)
    im = imread(images{im_i});
    if size(im, 3) == 1
      im = repmat(im, [1 1 3]);
    end
    [~,img_id,~] = fileparts(images{im_i});
    for method_i = 1:numel(method_configs)
      progress = (im_i-1) * numel(method_configs) + method_i;
      method = method_configs(method_i);
      fprintf('computing candidates (%s) %d/%d\n', ...
        method.name, progress, num_iterations);
      
      if numel(method.rerun_num_candidates) > 0
        n = numel(method.rerun_num_candidates);
        try
          read_candidates_mat(method.candidate_dir, img_id);
          continue;
        catch
        end
        candidates = cell(n, 1);
        scores = cell(n, 1);
        for cand_idx = 1:n
          t_num_candidates = method.rerun_num_candidates(cand_idx);
          [candidates{cand_idx}, scores{cand_idx}] = method.extract(im, t_num_candidates);
        end
        save_candidates_mat(method.candidate_dir, img_id, candidates, scores, method.rerun_num_candidates);
      else
        try
          read_candidates_mat(method.candidate_dir, img_id);
          continue;
        catch
        end
        t_num_candidates = num_candidates;
        if ~isempty(method.gt_recall_num_candidates)
          t_num_candidates = method.gt_recall_num_candidates;
        end
        [candidates, scores] = method.extract(im, t_num_candidates);
        save_candidates_mat(method.candidate_dir, img_id, candidates, scores);
      end
    end
  end
end
