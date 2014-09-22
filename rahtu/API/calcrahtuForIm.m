function proposals=calcrahtuForIm(input,rahtuconfig )
    
if(isstr(input))
        im = im2double(imread(input));
else
        im = im2double(input); % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end
        
[boxes,scores]=mvg_runObjectDetection(im);
        
if(isfield(rahtuconfig.opts,'numProposals'));
	numProposals=rahtuconfig.opts.numProposals;

	if(size(boxes,1)>=numProposals)
		boxes=boxes(1:numProposals,:);
		labels=labels(1:numProposals);
	else
        	fprintf('Only %d proposals were generated for the input image\n',size(boxes,1));
	end
end
            
proposals.boxes=boxes;
proposals.scores = scores;

end

