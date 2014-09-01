function [ params ] = setEdgeBoxesParamsFromConfig( config)

%%Loading Default Parameters here
%(1) main parameters 
%   .name           - [] target filename (if specified return is 1)
%   .alpha          - [.65] step size of sliding window search
%   .beta           - [.75] nms threshold for object proposals
%   .minScore       - [.01] min score of boxes to detect
%   .maxBoxes       - [1e4] max number of boxes to detect

config.params.name=[];
if isfield(config.params, 'alpha')
	config.params.alpha=[config.params.alpha];
end
if isfield(config.params, 'beta')
	config.params.beta=[config.params.beta];
end
if isfield(config.params, 'minScore')
	config.params.minScore=[config.params.minScore];
end
if isfield(config.params, 'maxBoxes')
	config.params.maxBoxes=[config.params.maxBoxes];
end


%(2)  additional parameters, safe to ignore and leave at default vals

%   .edgeMinMag     - [.1] increase to trade off accuracy for speed
%   .edgeMergeThr   - [.5] increase to trade off accuracy for speed
%   .clusterMinMag  - [.5] increase to trade off accuracy for speed
%   .maxAspectRatio - [3] max aspect ratio of boxes
%   .minBoxArea     - [1000] minimum area of boxes
%   .gamma          - [2] affinity sensitivity, see equation 1 in paper
%   .kappa          - [1.5] scale sensitivity, see equation 3 in paper

if isfield(config.params, 'edgeMinMag')
	config.params.edgeMinMag = [config.params.edgeMinMag];
end
if isfield(config.params, 'edgeMergeThr')
	config.params.edgeMergeThr = [config.params.edgeMergeThr];
end
if isfield(config.params, 'clusterMinMag')
	config.params.clusterMinMag  = [config.params.clusterMinMag];
end
if isfield(config.params, 'maxAspectRatio')
	config.params.maxAspectRatio = [config.params.maxAspectRatio];
end
if isfield(config.params, 'minBoxArea')
	config.params.minBoxArea= [config.params.minBoxArea] ;
end
if isfield(config.params, 'gamma')
	config.params.gamma=[config.params.gamma];
end
if isfield(config.params, 'kappa')
	config.params.kappa=[config.params.kappa];
end

params = config.params;

end

