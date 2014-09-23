function [boxes, scores, num_candidates] = read_candidates_mat(dirname, img_id)
  matfile = fullfile(dirname, sprintf('%s.jpg.mat', img_id));
  % default value
  num_candidates = 10000;
  load(matfile);
  
  boxes=proposals.boxes;
  if(isfield(proposals,'scores'))
  	scores=proposals.scores;
  else
	scores=[];
  end
end
