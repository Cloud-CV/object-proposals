function proposal = generateProposals(imLoc, config)

% Based on the demo.m file included in the Selective Search
% IJCV code.
addpath(genpath('../../'));
im=imread(imLoc);
im_width=config.params.imWidth;
%to scale or not?
if ~isfield(config.params, 'imWidth')
  im_width = [];
  scale = 1;
else
  scale = size(im, 2) / im_width;
end
if scale ~= 1
  im = imresize(im, [NaN im_width]);
end

% config.params: Note that this controls the number of hierarchical
% segmentations which are combined.


if(config.opts.mode=='fast')
  colorTypes =  {'Hsv', 'Lab'}; % 'Fast' uses HSV and Lab
  simFunctionHandles = {@SSSimColourTextureSizeFillOrig, ...
					    @SSSimTextureSizeFill}; % Two different merging strategies
  ks =[50 100];

else
  colorTypes=config.params.colorTypes;
  simFunctionHandles=config.params.simFunctionHandles;
  ks=config.params.ks;
end

sigma=config.params.sigma;
minBoxWidth =config.parmas.minBoxWidth;
numProposals=config.opts.numProposals;

idx = 1;
for j = 1:length(ks)
  k = ks(j); % Segmentation threshold k
  minSize = k; % We set minSize = k
  for n = 1:length(colorTypes)
    colorType = colorTypes{n};
    [boxesT{idx} blobIndIm blobBoxes hierarchy priorityT{idx}] = ...
      Image2HierarchicalGrouping(im, sigma, k, minSize, colorType, simFunctionHandles);
    idx = idx + 1;
  end
end
boxes = cat(1, boxesT{:}); % Concatenate boxes from all hierarchies
priority = cat(1, priorityT{:}); % Concatenate priorities

% Do pseudo random sorting as in paper
priority = priority .* rand(size(priority));
[priority sortIds] = sort(priority, 'ascend');
boxes = boxes(sortIds,:);

boxes = FilterBoxesWidth(boxes, minBoxWidth);
boxes = BoxRemoveDuplicates(boxes);

if scale ~= 1
  boxes = (boxes - 1) * scale + 1;
end

if(isfield(config.opts,'numProposals'))
numProposals=config.opts.numProposals;
	if(size(boxes,1)>=numProposals)
  		boxes=boxes(1:numProposals,:);
	else
  		fprintf('Only %d proposals were generated\n',size(boxes,1));
	end
end
%reset boxes  to xmin ymin xmax ymax
boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3);
proposal.boxes=boxes;
