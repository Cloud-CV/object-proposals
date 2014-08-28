function  generateProposalsForImages(range)
addpath(genpath('../'));
config=createConfig();

imageLoc=config.path.input;
outputLoc=config.path.output;
%extension inclues .
imageExt=config.param.imageExt;
images=dir([imageLoc '*' imageExt]);


for i=range
	imName=images(i).name;
	image=imread([imageLoc imName]);
	rankedProposals=generate_proposals(image);
	proposalFileName=strrep(imName,imageExt,'.mat');
	save([outputLoc proposalFileName],'rankedProposals');
end

