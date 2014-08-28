function [ output_args ] = calcEdgeBoxes( config )
%EDGEBOXES Summary of this function goes here
%   Detailed explanation goes here

ebconfig = config.edgeBoxes;

% load pre-trained edge detection model and set opts
if(~exist(ebconfig.modelPath,'dir')), return; end
model = load(ebconfig.modelPath);
model = model.model;
model.opts.multiscale = 0;
model.opts.sharpen = 2;
model.opts.nThread = 4;

%Write code to set options 
% call edgeBoxes() to get back options
opts = edgeBoxes()
opts.alpha = ebconfig.opts.alpha;
opts.beta = ebconfig.opts.beta;
opts.minScore = ebconfig.opts.minScore;
opts.maxBoxes = ebconfig.opts.maxBoxes;

%Check if image location exists or not.

if(~exist(ebconfig.imageLocation, 'dir'))
	fprintf("Image Location does not exist. Please check path once again \n");
	return;
end

if(~exist(ebconfig.outputLocation, 'dir'))
	fprintf("Image Location does not exist. Please check path once again \n");
	return;
end


imageIds = textread([config.path.inputLoc config.list.imageList],'%s%*[^\n]');

%Load All images in a particular folder
images = dir(ebconfig.imageLocation);
images = regexpi({image.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];


for image=1:length(images)

	im=imread([ebconfig.imageLocation image.name]);
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	
	bbs=edgeBoxes(im,model,opts);

	saveFile=[image.name '.mat'];
	save([saveLoc saveFile], 'bbs');
end

end

