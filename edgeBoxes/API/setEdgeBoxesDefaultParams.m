function config = setEdgeBoxesDefaultParams()
%SETDEFAULTPARAMS Summary of this function goes here
%   Detailed explanation goes here

%%Loading Default Parameters here
%(1) main parameters 
%   .name           - [] target filename (if specified return is 1)
%   .alpha          - [.65] step size of sliding window search
%   .beta           - [.75] nms threshold for object proposals
%   .minScore       - [.01] min score of boxes to detect
%   .maxBoxes       - [1e4] max number of boxes to detect

config.params.name=[];
config.params.alpha=[0.65];
config.params.beta=[0.75];
config.params.minScore=[0.01];
config.params.maxBoxes=[1e4];



%(2)  additional parameters, safe to ignore and leave at default vals

%   .edgeMinMag     - [.1] increase to trade off accuracy for speed
%   .edgeMergeThr   - [.5] increase to trade off accuracy for speed
%   .clusterMinMag  - [.5] increase to trade off accuracy for speed
%   .maxAspectRatio - [3] max aspect ratio of boxes
%   .minBoxArea     - [1000] minimum area of boxes
%   .gamma          - [2] affinity sensitivity, see equation 1 in paper
%   .kappa          - [1.5] scale sensitivity, see equation 3 in paper

config.params.edgeMinMag = [.1];
config.params.edgeMergeThr = [.5];
config.params.clusterMinMag  = [.5];
config.params.maxAspectRatio = [3];
config.params.minBoxArea= [1000] ;
config.params.gamma=[2];
config.params.kappa=[1.5];

end

