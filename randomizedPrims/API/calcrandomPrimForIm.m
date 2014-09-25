function proposals=calcrandomPrimForIm( input, rpconfig )
    
if(isstr(input))
	im = im2uint8(imread(input));
else
        im = im2uint8(input); % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end 
[boxes]=RP(im,rpconfig.params);        
if(isfield(rpconfig.opts,'numProposals'))
        numProposals=rpconfig.opts.numProposals;
        if(size(boxes,1)>=numProposals)
        	boxes=boxes(1:numProposals,:);
            else
                fprintf('Only %d proposals were generated for the input image\n',size(boxes,1));
            end
        end

proposals.boxes=boxes;
end

