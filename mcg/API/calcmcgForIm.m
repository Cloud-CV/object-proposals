function proposals=calcmcgForIm( input, mcgconfig)
rmpath(genpath([pwd '/dependencies/structuredEdges/release']));
if(ischar(input))
	im = imread(input);
else
    im = input; % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end


[candidates, ~] = im2mcg(im, mcgconfig.params.mode);
boxes=candidates.bboxes;
labels=candidates.labels; 
if(isfield(mcgconfig.opts,'numProposals'))
	numProposals=mcgconfig.opts.numProposals;
	if(size(boxes,1)>=numProposals)
   		boxes=boxes(1:numProposals,:);
      		labels=labels(1:numProposals);
	else
    		fprintf('Only %d proposals were generated for the input image\n',size(boxes,1));
	end
end
boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
proposals.boxes=boxes;
proposals.scores = candidates.bboxes_scores;
proposals.regions.labels=labels;
proposals.regions.superpixels=candidates.superpixels;
addpath(genpath([pwd '/dependencies/structuredEdges/release']));
end

