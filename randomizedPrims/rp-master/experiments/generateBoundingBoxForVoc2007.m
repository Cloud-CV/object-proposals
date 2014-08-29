function  generateProposalsForImages(range)

cd('../');
addpath(genpath(pwd));

setup;
addpath('matlab');
addpath('cmex');

config=createConfig();
params=LoadConfigFile('config/rp.mat');


imageLoc=config.path.input;
outputLoc=config.path.output;
%extension inclues .
imageExt=config.param.imageExt;
images=dir([imageLoc '*' imageExt]);

for i=1:4952
        imName=images(i).name;
        image=imread([imageLoc imName]);
        
	if(~size(image,3)==3)
		image=repmat(image,[1 1 3]);
	end
        
	[proposals]=RP(image,params);
        proposalFileName=strrep(imName,imageExt,'.mat');
        save([outputLoc proposalFileName],'proposals');
end

