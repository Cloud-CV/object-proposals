function proposals = calcselective_searchForIm( input,ssconfig)

colorTypes=ssconfig.params.colorTypes;
simFunctionHandles=ssconfig.params.simFunctionHandles;
ks=ssconfig.params.ks;
im_width=ssconfig.params.imWidth;
sigma=ssconfig.params.sigma;
minBoxWidth =ssconfig.params.minBoxWidth;
   
if(isstr(input))
        im = im2uint8(imread(input));
else
        im = im2uint8(input); % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end
if ~isfield(ssconfig.params, 'imWidth')
	im_width = [];
        scale = 1;
else
        scale = size(im, 2) / im_width;
end
        
if scale ~= 1
        im = imresize(im, [NaN im_width]);
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

if(isfield(ssconfig.opts,'numProposals'))
        numProposals=ssconfig.opts.numProposals;
        if(size(boxes,1)>=numProposals)
        	boxes=boxes(1:numProposals,:);
        else
                fprintf('Only %d proposals were generated for input image \n',size(boxes,1));
        end
end 
        
% reset boxes to xmin ymin xmax ymnx
boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
proposals.boxes=boxes;
        
    

