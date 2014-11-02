function proposals= calcEdgeBoxesForIm( input, ebconfig )
rmpath(genpath([pwd '/rigor']));
rmpath(genpath([pwd '/mcg/']));
if(isstr(input))
	im = im2double(imread(input));
else
        im = im2double(input); % Just to make input consistent
end
if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
end
% load pre-trained edge detection model and set opts
if(~exist(ebconfig.modelPath))
    fprintf('Path to model does not exist. Please make sure you give a proper full path\n');
    return; 
end

model = load(ebconfig.modelPath);
model = model.model;
model.opts.multiscale = 0;
model.opts.sharpen = 2;
model.opts.nThread = 4;

%Write code to set options 
% call edgeBoxes() to get back options

opts = edgeBoxes();
bbs=edgeBoxes(im,model,opts);
if(isfield((ebconfig.opts),'numProposals'))
	numProposals=ebconfig.opts.numProposals;
        if(size(bbs,1)>=numProposals)
       	        bbs=bbs(1:numProposals);
       	else
               	fprintf('Only %d proposals were generated for input image.\n',size(bbs,1));
        end
end
%edges boxes produces baoxes as "[x y w, h]"
%we convert to [x y x+w y+h]==[xmin ymin xmax ymax]
boxes=bbs(:,1:4);
boxes=[boxes(:,1) boxes(:,2) boxes(:,1)+ boxes(:,3) boxes(:,2)+boxes(:,4)];
proposals.boxes= boxes;
proposals.scores = bbs(:,5);

addpath(genpath([pwd '/mcg/']));
addpath(genpath([pwd '/rigor']));
end


