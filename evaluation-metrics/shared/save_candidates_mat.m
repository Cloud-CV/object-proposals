function save_candidates_mat(dirname, img_id, boxes, scores, num_candidates, subdirlen)
% Save candidates to disk.

  if nargin < 5
    num_candidates = [];
  end
  if nargin < 6
    subdirlen = 4;
  end
  subdir = img_id(1:subdirlen);

  path = fullfile(dirname, subdir);
  if ~exist(path, 'dir')
    mkdir(path);
  end
  matfile = fullfile(dirname, subdir, sprintf('%s.mat', img_id));
  save(matfile, 'boxes', 'scores', 'num_candidates');
end
