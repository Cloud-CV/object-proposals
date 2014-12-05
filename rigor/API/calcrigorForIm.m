function proposals= calcRigorForIm( input, rigorconfig )
%RIGOR Summary of this function goes here
%   Detailed explanation goes here

%RIGOR doesnt suppoert .mat as an input yet
if ismac
    error('rigor not supported on macOS');
end
im = input;
	[masks]=rigor_obj_segments(im,'force_recompute',true);

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
	proposals.regions=masks;
end
