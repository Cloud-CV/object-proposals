function calcrantalankila( config )
raconfig = config.rantalankila;
    
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];
if(~exist([config.outputLocation '/rantalankila'], 'dir'))
	mkdir(config.outputLocation,'/rantalankila')
end 
    % Running Spagglom_options script to give opts.
for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(config.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end
        fprintf('Calculating Rantalankila Proposals for %s\n', imname);
        proposals=calcrantalankilaForIm(im,raconfig);

        saveFile=[imname '.mat'];
        save([config.outputLocation '/rantalankila/' saveFile], 'proposals');
end

    

