function evaluationStartup(proposal_root_path)

  addpath(fullfile(proposal_root_path, 'util'));
  addpath(fullfile(proposal_root_path, 'shared'));
  addpath(fullfile(proposal_root_path, 'recall'));
  addpath(genpath(fullfile(proposal_root_path, 'aboEvaluation')));

end