function  generateProposalsForImages()

cd('../');
addpath(genpath(pwd));

setup;
addpath('matlab');
addpath('cmex');

config=createConfig();

%params=LoadConfigFile('config/rp.mat');



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
	
	boxes=RP(image,config.params);
	proposals.boxes=boxes
        proposalFileName=strrep(imName,imageExt,'.mat');
        save([outputLoc proposalFileName],'proposals');
end

