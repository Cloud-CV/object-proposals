function proposals=calcrantalankilaForIm(input, raconfig )
spagglom_options;
if(isstr(input))
        im = im2uint8(imread(input));
else
        im = im2uint8(input); % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end
[region_parts, orig_sp] = spagglom(im,raconfig.params );
boxes=zeros(length(region_parts),4);
for i=1:length(region_parts)
	mask=zeros(size(image));
        region=region_parts{i};
        for j=1:length(region)
        	sp=region(j);
                pixels=orig_sp{sp}.pixels;
                for k=1:length(pixels)
                	mask(pixels(k,1),pixels(k,2))=1;
                end
        end
            	boxes(i,:)=mask2box(mask);
end
if(isfield(raconfig.opts,'numProposals'))
	numProposals=raconfig.opts.numProposals;
        if(size(boxes,1)>=numProposals)
        	boxes=boxes(1:numProposals,:);
                labels=labels(1:numProposals);
        else
                fprintf('Only %d proposals were generated for input image\n',size(boxes,1));
        end
end

proposals.boxes=boxes;
proposals.regions.region_parts=region_parts;
proposals.regions.orig_sp= orig_sp;
end

    

