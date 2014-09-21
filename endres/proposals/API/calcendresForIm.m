function proposals=calcendresForIm(input,endresconfig)
%INPUTS
%input: image location or image
%endresconfig: config of this proposal from configjson
        if(isstr(input))
 		im = im2double(imread(input));
	else
   		im = im2double(input); % Just to make input consistent
	end
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	[ranked_regions superpixels image_data]=generate_proposals(im);
		
	boxes=zeros(length(ranked_regions),4);

	for j=1:length(ranked_regions)
		boxes(j,:)=mask2box(ismember(superpixels, ranked_regions{j}));
	end
	if(isfield(endresconfig.opts,'numProposals'))
        	numProposals=endresconfig.opts.numProposals;
	        if(size(boxes,1)>=numProposals)
			%take teh top proposals as the proposals are ranked that way.
        	        boxes=boxes(1:numProposals,:);
                	ranked_regions=ranked_regions(1:numProposals);
	        else
        	        fprintf('Only %d proposals were generated for input image\n',size(boxes,1));
        	end
	end
	boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
	proposals.boxes=boxes;
	proposals.regions.ranked_regions=ranked_regions;
	proposals.regions.superpixels=superpixels;
	proposals.regions.image_data=image_data;
	end


