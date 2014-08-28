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
opts.alpha = ebconfig.opts.alpha;
opts.beta = ebconfig.opts.beta;
opts.minScore = ebconfig.opts.minScore;
opts.maxBoxes = ebconfig.opts.maxBoxes;

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

	saveFile=[imname '.mat'];
	save([ebconfig.outputLocation saveFile], 'bbs');
end

end

