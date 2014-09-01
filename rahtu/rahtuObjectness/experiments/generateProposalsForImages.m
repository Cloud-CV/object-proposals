function  generateProposalsForImages()
addpath(genpath('../'));
config=createConfig();
cd ..
imageLoc=config.path.input;
outputLoc=config.path.output;
%extension inclues .
imageExt=config.opts.imageExt;
images=dir([imageLoc '*' imageExt]);


for i=1:length(images)
        imName=images(i).name;
        image=imread([imageLoc imName]);
        
	if(~size(image,3)==3)
		image=repmat(image,[1 1 3]);
	end
        
	[boxes,scores]=mvg_runObjectDetection(image,config.params);
	if(isfield(config.opts,'numProposals'))
		numProposals=config.opts.numProposals;
		if(size(boxes,1)>=numProposals)
			boxes=boxes(1:numProposals,:);
                        labels=labels(1:numProposals);
		else
			fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imName);
                end
	end
	proposals.boxes=boxes;
        proposalFileName=strrep(imName,imageExt,'.mat');
        save([outputLoc proposalFileName],'proposals');
end

