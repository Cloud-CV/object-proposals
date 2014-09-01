%evaluate on the val2 set from imagenet2013 
%use the default parameters as used in the demo:
%% load pre-trained edge detection model and set opts (see edgesDemo.m)
addpath(genpath('../'));

model=load('models/forest/modelBsds'); model=model.model;
model.opts.multiscale=0; model.opts.sharpen=2; model.opts.nThreads=4;

%% set up opts for edgeBoxes (see edgeBoxes.m)
opts = edgeBoxes;
opts.alpha = .65;     % step size of sliding window search
opts.beta  = .75;     % nms threshold for object proposals
opts.minScore = .01;  % min score of boxes to detect
opts.maxBoxes = 1e4;  % max number of boxes to detect


%config specifies the image location location to save output etc.
config=createConfig();
imageLoc=config.path.imageLoc;
saveLoc=config.path.outputLoc;
ext=config.opts.imageExt;

imageExt=config.opts.imageExt;
images=dir([imageLoc '*' imageExt]);


for i=1:length(images)

	imageName=images(i).name;
	im=imread([imageLoc imageName]);
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	bbs=edgeBoxes(im,model,opts);
	if(isfield((config.opts),'numProposals'))
		numProposals=config.opts.numProposals;
	        if(size(bbs,1)>=numProposals)
        	        bbs=bbs(1:numProposals);
        	else
                	fprintf('Only %d proposals were generated for image: %s\n',size(bbs,1),imageName);
        	end
	end
 	%edges boxes produces baoxes as "[x y w, h]"
	%we convert to [x y x+w y+h]==[xmin ymin xmax ymax]
        boxes=bbs(:,1:4);
	boxes=[boxes(:,1) boxes(:,2) boxes(:,1)+ boxes(:,3) boxes(:,2)+boxes(:,4)];
	proposals.boxes= boxes;
	proposalFileName=strrep(imageName,imageExt,'.mat');

	save([saveLoc proposalFileName], 'proposals');
end

