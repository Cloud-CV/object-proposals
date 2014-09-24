function proposals = calcobjectnessForIm( input,objectnessconfig )

if(isstr(input))
	im = im2double(imread(input));
else
        im = im2double(input); % Just to make input consistent
end

if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end


if(isfield(objectnessconfig.opts,'numProposals'))    
	bbs = runObjectness(im,objectnessconfig.opts.numProposals,objectnessconfig.params);
else
	%generate 1000 by default
	bbs=runObjectness(im,1000,objectnessconfig.params);
end
if(isfield((objectnessconfig.opts),'numProposals'))
	numProposals=objectnessconfig.opts.numProposals;
        if(size(bbs,1)>=numProposals)
       	        bbs=bbs(1:numProposals);
       	else
               	fprintf('Only %d proposals were generated for input image\n',size(bbs,1));
       	end
end
size(bbs)
boxes=bbs(:,1:4);
proposals.boxes= boxes;
proposals.scores=bbs(:,5);


end

