function calcRaSegments( configjson )
    raconfig = configjson.rantalankila;
    
    run(fullfile(raconfig.vlfeatpath, 'toolbox/vl_setup'))
    
    if(~exist(raconfig.imageLocation, 'dir'))
        fprintf('Image Location does not exist. Please check path once again \n');
        return;
    end
    
    images = dir(raconfig.imageLocation);
    images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
    images = [images{:}];
    
    % Running Spagglom_options script to give opts.
    spagglom_options;

    for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(raconfig.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end
        
        fprintf('Calculating Rantalankila Segments for %s\n', imname);
        [region_parts, orig_sp] = spagglom(im, opts);

        boxes=zeros(length(region_parts),4);
        for i=1:length(region_parts)
                mask=zeros(size(im));
                size(im)
                region=region_parts{i}
                for j=1:length(region)
                        sp=region(i)
                        pixels=orig_sp{sp};
                        for k=1:length(pixels)
                                mask(pixels(k,1),pixels(k,2))=1;
                        end
                end

        end

        if(isfield(raconfig.opts,'numProposals'))
            numProposals=raconfig.opts.numProposals;
            if(size(boxes,1)>=numProposals)
                boxes=boxes(1:numProposals,:);
                            labels=labels(1:numProposals);
            else
                fprintf('Only %d proposals were generated for image:%s\n',size(boxes,1),imname);
            end
        end

        proposals.boxes=boxes;
        saveFile=[imname '.mat'];
        save([raconfig.outputLocation saveFile], 'proposals');
    end

    
end

