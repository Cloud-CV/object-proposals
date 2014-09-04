function proposal = generateProposals()

% Based on the demo.m file included in the Selective Search
% IJCV code.
addpath(genpath('../../'));

% config.params: Note that this controls the number of hierarchical
% segmentations which are combined.





config=createConfig();
imageLoc=config.path.input;
saveLoc=config.path.output;
imageExt=config.opts.imageExt;


colorTypes=config.params.colorTypes;
simFunctionHandles=config.params.simFunctionHandles;
ks=config.params.ks;

sigma=config.params.sigma;
minBoxWidth =config.parmas.minBoxWidth;
numProposals=config.opts.numProposals;



images=dir([imageLoc '*' imageExt]);
for i=1:length(images)
	imageName=images(i).name;
	im=imread([imageLoc imageName]);
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

	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end

		

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
  			fprintf('Only %d proposals were generated for image: %s\n',size(boxes,1),imageName);
		end
	end 
	% reset boxes to xmin ymin xmax ymnx
	boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
	proposals.boxes=boxes;

	proposalFileName=strrep(imageName,imageExt,'.mat');
        save([saveLoc proposalFileName], 'proposals');
end
