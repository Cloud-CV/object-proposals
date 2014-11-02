function proposals=calcmcgForIm( input, mcgconfig)
rmpath(genpath([pwd '/dependencies/structuredEdges/release']));
if(isstr(input))
	im = im2double(imread(input));
else
        im = im2double(input); % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end


[candidates, ~] = im2mcg(mcgconfig.root_dir, im, mcgconfig.opts.mode);
boxes=zeros(length(candidates.labels),4);
for j=1:length(candidates.labels)
	boxes(j,:)=mask2box(ismember(candidates.superpixels,candidates.labels{j}));
end
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
proposals.scores = candidates.scores;
proposals.regions.labels=labels;
proposals.regions.superpixels=candidates.superpixels;
addpath(genpath([pwd '/dependencies/structuredEdges/release']));
end

