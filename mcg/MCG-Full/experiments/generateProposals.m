function proposals = generateProposals(imLoc, config)
cd('../');
addpath(genpath(pwd));
addpath(genpath('../../../utils/'));
%build;
%install;

image=imread([imLoc]);
if(~size(image,3)==3)
	image=repmat(image,[1 1 3]);
end
 %andidates stores bounding boxes too..
mode=config.opts.mode;

[candidates,~]= im2mcg(image,mode);
[candidates,scores]= im2mcg(image,'accurate');
boxes=zeros(length(candidates.labels),4);
for j=1:length(candidates.labels)
	boxes(j,:)=mask2box(ismember(candidates.superpixels,candidates.labels{j}));
end
if(isfield(config.opts,'numProposals'))
	numProposals=config.opts.numProposals;
        if(size(boxes,1)>=numProposals)
	        boxes=boxes(1:numProposals,:);
                labels=candidates.labels(1:numProposals);
        else
                fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imName);
	end
end
boxes=[boxes(:,2) boxes(:,1) boxes(:,4) boxes(:,3)];
proposals.boxes=boxes;
proposals.regions.labels=labels;
proposals.regions.superpixels=candidates.superpixels;

