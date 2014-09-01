function proposals=generatePRoposals(imLoc,config)
%% load pre-trained edge detection model and set opts (see edgesDemo.m)

addpath(genpath('../'));

model=load('models/forest/modelBsds'); model=model.model;
model.opts.multiscale=0; model.opts.sharpen=2; model.opts.nThreads=4;

numProposals=config.opts.numProposals;

%config specifies the image location location to save output etc.
opts=config.params;
imLoc
bbs=edgeBoxes(imLoc,model,opts);

if(isfield(config.opts,'numProposals'))
numProposals=config.opts.numProposals;
	if(size(bbs,1)>=numProposals)
  		bbs=bbs(1:numProposals,:);
	else
  		fprintf('Only %d proposals were generated\n',size(boxes,1));
end
boxes=bbs(:,1:4);
proposals.boxes=boxes;

