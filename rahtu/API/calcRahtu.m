function calcRahtu( configjson )
    rahtuconfig = configjson.rahtu;
    
    if(~exist(rahtuconfig.imageLocation, 'dir'))
        fprintf('Image Location does not exist. Please check path once again \n');
        return;
    end
    
    images = dir(rahtuconfig.imageLocation);
    images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
    images = [images{:}];
    
    for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(rahtuconfig.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end
        
        fprintf('Running Randomized Prims for %s\n', imname);
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
        save([rahtuconfig.outputLocation saveFile], 'proposals');
    end

end

