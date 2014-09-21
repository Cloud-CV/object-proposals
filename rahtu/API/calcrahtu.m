function calcrahtu( config )
    rahtuconfig = config.rahtu;
    
    if(~exist([config.outputLocation '/rahtu'], 'dir'))
            mkdir(config.outputLocation,'/rahtu')
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
        
        fprintf('Generating Rahtu proposals for %s\n', imname);
        proposals= calcrahtuForIm(im,rahtuconfig);
            
        saveFile=[imname '.mat'];
        save([config.outputLocation '/rahtu/' saveFile], 'proposals');
    end

