function calcgop( config )
gopconfig = config.gop; 
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];
    
if(~exist([config.outputLocation '/gop'], 'dir'))
	mkdir(config.outputLocation,'/gop')
end
for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(config.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end
        
        fprintf('Generating Geodesic Object Proposals for %s\n', imname);
        proposals=calcgopForIm(im,gopconfig);
        saveFile=[imname '.mat'];
        save([config.outputLocation '/gop/' saveFile], 'proposals');
end