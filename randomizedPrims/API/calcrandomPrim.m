function calcrandomPrim( config )
    rpconfig = config.randomPrim;
    params=LoadConfigFile(fullfile(rpconfig.rpPath, 'config/rp.mat'));
    
    if(~exist(config.imageLocation, 'dir'))
        fprintf('Image Location does not exist. Please check path once again \n');
        return;
    end
    
    images = dir(config.imageLocation);
    images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
    images = [images{:}];
    
    for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(config.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end
        
        fprintf('Running Randomized Prims for %s\n', imname);
        [boxes]=RP(im,params);
        
        if(isfield(rpconfig.opts,'numProposals'))
            numProposals=rpconfig.opts.numProposals;
            if(size(boxes,1)>=numProposals)
                boxes=boxes(1:numProposals,:);
                            labels=labels(1:numProposals);
            else
                fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imname);
            end
        end

        proposals.boxes=boxes;
        saveFile=[imname '.mat'];
        if(~exist([config.outputLocation '/randomPrim'], 'dir'))
        	mkdir(config.outputLocation,'/randomPrim')
        end
        save([config.outputLocation '/randomPrim/' saveFile], 'proposals');
    end
end

