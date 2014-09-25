function calcRigor( config )

%RIGOR Summary of this function goes here
%   Detailed explanation goes here

rigorconfig = config.rigor;
param = rigorconfig.params.param_set;

%Check if image location exists or not.

if(~exist(config.imageLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

if(~exist(config.outputLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

%Load All images in a particular folder
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

for i=1:length(images)
    imname = char(images(i));
    impath = fullfile(config.imageLocation, imname);
    whos impath
	im=imread(impath);
    
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	fprintf('Calculating Rigor for %s\n', imname);
	[masks]=rigor_obj_segments(impath,'force_recompute',true);

	if(isfield((rigorconfig.opts),'numProposals'))
		numProposals=rigorconfig.opts.numProposals;
	        if(size(masks,3)>=numProposals)
        	        masks=masks(:,:,1:numProposals);
        	else
                	fprintf('Only %d proposals were generated for image: %s\n',size(masks,3),imname);
        	end
	end
	boxes=zeros(size(masks,3),4);
	for j=1:size(masks,3)
		boxes(j,:)=mask2box(masks(:,:,j));
	end
	proposals.boxes= boxes;
	saveFile=[imname '.mat'];
	save([config.outputLocation saveFile], 'proposals');
        fprintf('saved proposals');
        %disp(boxes);
        %disp(proposals);
end

end

