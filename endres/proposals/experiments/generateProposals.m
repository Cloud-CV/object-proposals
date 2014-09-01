function proposals=  generateProposals(imLoc,config)
%INPUT
%im: image location
%config :use createConfig for info
%OUTPUT
%proposals: struct with two fields boxes and regions
%           boxes[xmin ymin xmax ymax]
% To get the pixelmask for the ith region:
%    mask = ismember(superpixels,ranked_ regions{i});


addpath(genpath('../'));
addpath(genpath('/home/gneelima/work/code/objectProposals/utils/'));
%config=createConfig();
image=imread(imLoc);
[ranked_regions superpixels image_data]=generate_proposals(image);
boxes=zeros(length(ranked_regions),4);
for j=1:length(ranked_regions)
	boxes(j,:)=mask2box(ismember(superpixels, ranked_regions{j}));
end

if(isfield(config.opts,'numProposals'))
	numProposals=config.opts.numProposals;

	if(size(boxes,1)>=numProposals)
  		boxes=boxes(1:numProposals,:);
  		ranked_regions=ranked_regions{1:numProposals};  
	else
  		fprintf('Only %d proposals were generated\n',size(boxes,1));
	end
end

proposals.boxes=boxes;
proposals.regions.ranked_regions=ranked_regions;
proposals.regions.superpixels=superpixels;
proposals.regions.image_data=image_data;

