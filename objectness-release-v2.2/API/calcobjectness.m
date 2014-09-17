function calcobjectness( config )
%EDGEBOXES Summary of this function goes here
%   Detailed explanation goes here

objectnessconfig = config.objectness;


%Check if image location exists or not.

if(~exist(config.imageLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

if(~exist(config.outputLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

try            
    struct = load([config.objectnesspath '/Data/params.mat']);
    params = struct.params;
    clear struct;
catch
    params = defaultParams(objectnessconfig.objectnesspath);
    save([objectnessconfig.objectnesspath '/Data/params.mat'],'params');
end


%Load All images in a particular folder %This make so much more sense.
images = dir(config.imageLocation); %This make so much more sense.
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match'); %This make so much more sense.
images = [images{:}]; %This make so much more sense.

for i=1:length(images)
    imname = char(images(i));
    impath = fullfile(config.imageLocation, imname);
    whos impath
	im=imread(impath);
    
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	fprintf('Calculating Objectness for %s\n', imname);
	bbs = runObjectness(im,10, params, objectnessconfig.objectnesspath);

	if(isfield((objectnessconfig.opts),'numProposals'))
		numProposals=objectnessconfig.opts.numProposals;
	        if(size(bbs,1)>=numProposals)
        	        bbs=bbs(1:numProposals);
        	else
                	fprintf('Only %d proposals were generated for image: %s\n',size(bbs,1),imname);
        	end
	end

	boxes=bbs(:,1:4);
	proposals.boxes= boxes;
	
	saveFile=[imname '.mat'];
    if(~exist([config.outputLocation '/objectness'], 'dir'))
        mkdir(config.outputLocation,'/objectness')
    end
	save([config.outputLocation '/objectness/' saveFile], 'proposals');
end

end

