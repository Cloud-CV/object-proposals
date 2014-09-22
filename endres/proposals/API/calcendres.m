function calcendres(config)
	%EDGEBOXES Summary of this function goes here
	%   Detailed explanation goes here

	endresconfig = config.endres;

	%Load All images in a particular folder
	images = dir(config.imageLocation);
	images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
	images = [images{:}];
        
        %check savelocation exists.
        if(~exist([config.outputLocation '/endres'], 'dir'))
            mkdir(config.outputLocation,'/endres')
        end

	for i=1:length(images)
	    imname = char(images(i));
	    impath = fullfile(config.imageLocation, imname);
	    im=imread(impath);
            fprintf('Generating proposals for image:%s\n',imname);
	    proposals=calcendresForIm(im,endresconfig);

	    saveFile=[imname '.mat'];
            save([config.outputLocation '/endres/' saveFile], 'proposals');
	end

end

