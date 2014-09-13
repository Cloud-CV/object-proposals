



config=createConfig();
imageLoc=config.path.imageLoc;
saveLoc=config.path.outputLoc;
ext=config.opts.imageExt;

imageExt=config.opts.imageExt;
images=dir([imageLoc '*' imageExt]);


for i=1:length(images)

	imageName=images(i).name;
	im=imread([imageLoc imageName]);
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	bbs=runObjectness(im,10);
	if(isfield((config.opts),'numProposals'))
		numProposals=config.opts.numProposals;
	        if(size(bbs,1)>=numProposals)
        	        bbs=bbs(1:numProposals);
        	else
                	fprintf('Only %d proposals were generated for image: %s\n',size(bbs,1),imageName);
        	end
	end
 	%edges boxes produces baoxes as" [x y w, h],
        boxes=bbs(:,1:4);
	proposals.boxes= boxes;
	proposalFileName=strrep(imageName,imageExt,'.mat');
	save([saveLoc proposalFileName], 'proposals');
end

