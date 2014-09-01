function  generateProposalsForImages(range)
cd('/home/gneelima/work/code/objectProposals/mcg/MCG-Full/');
addpath(genpath(pwd));

build;
install;

config=createConfig();

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
        %andidates stores bounding boxes too..
	[candidates,scores]= im2mcg(image,'accurate');
        proposalFileName=strrep(imName,imageExt,'.mat');
        save([outputLoc proposalFileName],'candidates','scores');
end

