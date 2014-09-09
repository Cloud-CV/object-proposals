function  generateProposalsForImages()
%boxes have this format: [xmin ymin xmax ymax]
addpath(genpath('../'));
addpath(genpath('../../../utils/'));
config=createConfig();

imageLoc=config.path.input;
outputLoc=config.path.output;
%extension inclues .
imageExt=config.opts.imageExt;
images=dir([imageLoc '*' imageExt]);


for i=1:length(images)
	imName=images(i).name;
	image=imread([imageLoc imName]);
	[ranked_regions superpixels image_data]=generate_proposals(image);
	boxes=zeros(length(ranked_regions),4);
	for j=1:length(ranked_regions)
		boxes(j,:)=mask2box(ismember(superpixels, ranked_regions{j}));
	end
	
	if(isfield(config.opts,'numProposals'))
        numProposals=config.opts.numProposals;

        if(size(boxes,1)>=numProposals)
                boxes=boxes(1:numProposals,:);
                ranked_regions=ranked_regions(1:numProposals);
        else
                fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imName);
        end
end
	%mask2box outputs  [ymin xmin ymax xmax]
	boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
	proposals.boxes=boxes;
	proposals.scores = [size(boxes,1):-1:1]`;
	proposals.regions.ranked_regions=ranked_regions;
	proposals.regions.superpixels=superpixels;
	proposals.regions.image_data=image_data;
        
	
	proposalFileName=strrep(imName,imageExt,'.mat');
	save([outputLoc proposalFileName],'proposals');
end

