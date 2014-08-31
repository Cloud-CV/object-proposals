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
        saveFile=[imname '.mat'];
        save([raconfig.outputLocation saveFile], 'region_parts', 'orig_sp');
    end

    
end

