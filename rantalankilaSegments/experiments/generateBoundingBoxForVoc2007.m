function  generateProposalsForImages(range)
cd('/home/gneelima/work/code/objectProposals/rantalankilaSegments/');
addpath(genpath('/home/gneelima/work/code/objectProposals/dependencies/'));
addpath(genpath(pwd));
VLFEAT='/home/gneelima/work/code/objectProposals/dependencies/vlfeat-0.9.16/';
run([VLFEAT 'toolbox/vl_setup']);

config=createConfig();
imageLoc=config.path.input;
outputLoc=config.path.output;

%extension inclues .
imageExt=config.param.imageExt;
images=dir([imageLoc '*' imageExt]);

spagglom_options;

for i=1:4952
        imName=images(i).name;
        image=imread([imageLoc imName]);
        
	if(~size(image,3)==3)
		image=repmat(image,[1 1 3]);
	end
        %candidates stores bounding boxes too..
	[region_parts, orig_sp]= spagglom(image,opts);
        proposalFileName=strrep(imName,imageExt,'.mat');
        save([outputLoc proposalFileName],'region_parts','orig_sp');
	fprintf('done with image\n');
end


