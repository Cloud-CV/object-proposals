function  generateProposalsForImages(range)
addpath(genpath('../'));
config=createConfig();

cd ..;
imageLoc=config.path.input;
outputLoc=config.path.output;
%extension inclues .
imageExt=config.param.imageExt;
images=dir([imageLoc '*' imageExt]);


for i=range
        imName=images(i).name;
        image=imread([imageLoc imName]);
        
	if(~size(image,3)==3)
		image=repmat(image,[1 1 3]);
	end
        
	[boxes,scores]=mvg_runObjectDetection(image);
        proposalFileName=strrep(imName,imageExt,'.mat');
        save([outputLoc proposalFileName],'boxes','scores');
end

