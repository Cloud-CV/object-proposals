function calcrahtu( config )
    rahtuconfig = config.rahtu;
    
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
        
        fprintf('Running Rahtu for %s\n', imname);
        [boxes,scores]=mvg_runObjectDetection(im);
        
        if(isfield(rahtuconfig.opts,'numProposals'))
            numProposals=rahtuconfig.opts.numProposals;

            if(size(boxes,1)>=numProposals)
                boxes=boxes(1:numProposals,:);
                            labels=labels(1:numProposals);
            else
                fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imname);
            end
        end
            
        proposals.boxes=boxes;
        proposals.scores = scores;
        saveFile=[imname '.mat'];
        if(~exist([config.outputLocation '/rahtu'], 'dir'))
            mkdir(config.outputLocation,'/rahtu')
        end
        save([config.outputLocation '/rahtu/' saveFile], 'proposals');
    end

end

