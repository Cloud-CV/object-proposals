function calcEdgeBoxes( config )
%EDGEBOXES Summary of this function goes here
%   Detailed explanation goes here

ebconfig = config.edgeBoxes;

% load pre-trained edge detection model and set opts
if(~exist(ebconfig.modelPath))
    fprintf('Path to model does not exist. Please make sure you give a proper full path\n');
    return; 
end

model = load(ebconfig.modelPath);
model = model.model;
model.opts.multiscale = 0;
model.opts.sharpen = 2;
model.opts.nThread = 4;

%Write code to set options 
% call edgeBoxes() to get back options

opts = edgeBoxes()
opts.alpha = ebconfig.params.alpha;
opts.beta = ebconfig.params.beta;
opts.minScore = ebconfig.params.minScore;
opts.maxBoxes = ebconfig.params.maxBoxes;

%Check if image location exists or not.

if(~exist(ebconfig.imageLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

if(~exist(ebconfig.outputLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

%Load All images in a particular folder
images = dir(ebconfig.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

for i=1:length(images)
    imname = char(images(i));
    impath = strcat(ebconfig.imageLocation, imname);
    whos impath
	im=imread(impath);
    
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	fprintf('Calculating Edge Boxes for %s\n', imname);
	bbs=edgeBoxes(im,model,opts);

	if(isfield((ebconfig.opts),'numProposals'))
		numProposals=ebconfig.opts.numProposals;
	        if(size(bbs,1)>=numProposals)
        	        bbs=bbs(1:numProposals);
        	else
                	fprintf('Only %d proposals were generated for image: %s\n',size(bbs,1),imname);
        	end
	end
 	%edges boxes produces baoxes as "[x y w, h]"
	%we convert to [x y x+w y+h]==[xmin ymin xmax ymax]
        boxes=bbs(:,1:4);
	boxes=[boxes(:,1) boxes(:,2) boxes(:,1)+ boxes(:,3) boxes(:,2)+boxes(:,4)];
	proposals.boxes= boxes;
	
	saveFile=[imname '.mat'];
	save([ebconfig.outputLocation saveFile], 'proposals');
end

end

