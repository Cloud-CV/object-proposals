function calcEndres(config)
	%EDGEBOXES Summary of this function goes here
	%   Detailed explanation goes here

	endresconfig = config.endres;

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
		fprintf('Calculating Endres for %s\n', imname);
		
	   	[ranked_regions superpixels image_data]=generate_proposals(im);
		
		boxes=zeros(length(ranked_regions),4);

		for j=1:length(ranked_regions)
			boxes(j,:)=mask2box(ismember(superpixels, ranked_regions{j}));
		end
		
		if(isfield(endresconfig.opts,'numProposals'))
	        numProposals=endresconfig.opts.numProposals;

	        if(size(boxes,1)>=numProposals)
	                boxes=boxes(1:numProposals,:);
	                ranked_regions=ranked_regions(1:numProposals);
	        else
	                fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imname);
	        end
		end

		boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
		proposals.boxes=boxes;
		proposals.scores = [size(boxes,1):-1:1];
		proposals.regions.ranked_regions=ranked_regions;
		proposals.regions.superpixels=superpixels;
		proposals.regions.image_data=image_data;

		saveFile=[imname '.mat'];
        if(~exist([config.outputLocation '/endres'], 'dir'))
            mkdir(config.outputLocation,'/endres')
        end
        xsave([config.outputLocation '/endres/' saveFile], 'proposals');
	end

end

