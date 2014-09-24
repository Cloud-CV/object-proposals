function [candidates, scores] = get_candidates(candidate_dir,method_config, img_id, num_candidates, allow_filtering)

  if nargin < 4
    allow_filtering = true;
  end

  [candidates, scores, rerun_num_candidates] = read_candidates_mat(candidate_dir, img_id);
  if iscell(candidates) && iscell(scores)
    [~,idx] = min(abs(rerun_num_candidates - num_candidates));
    candidates = candidates{idx};
    scores = scores{idx};
  end
  
  if allow_filtering
    if strcmp(method_config.opts.order, 'none')
      % nothing to do
    elseif strcmp(method_config.opts.order, 'biggest')
      w = candidates(:,3) - candidates(:,1) + 1;
      h = candidates(:,4) - candidates(:,2) + 1;
      areas = w .* h;
      [~,order] = sort(areas, 'descend');
      candidates = candidates(order,:);
      scores = scores(order,:);
    elseif strcmp(method_config.opts.order, 'smallest')
      w = candidates(:,3) - candidates(:,1) + 1;
      h = candidates(:,4) - candidates(:,2) + 1;
      areas = w .* h;
      [~,order] = sort(areas, 'ascend');
      candidates = candidates(order,:);
      scores = scores(order,:);
    elseif strcmp(method_config.opts.order, 'random')
      s = RandStream('mt19937ar','Seed',0);
      perm = randperm(s, size(candidates,1));
      candidates = candidates(perm,:);
      if numel(scores) > 0
        scores = scores(perm);
      end
    else
      [scores, argsort] = sort(scores, method_config.opts.order);
      candidates = candidates(argsort,:);
    end
    
    num_candidates = min(num_candidates, size(candidates, 1));
    candidates = candidates(1:num_candidates,:);
    if numel(scores) > 0
      scores = scores(1:num_candidates,:);
    end
  else
    error('this shouldn''t be used');
  end
end
