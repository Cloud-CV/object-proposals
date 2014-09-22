function calcrandomPrim( config )
rpconfig = config.randomPrim;
    
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];
    
if(~exist([config.outputLocation '/randomPrim'], 'dir'))
	mkdir(config.outputLocation,'/randomPrim')
end
for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(config.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end
        
        fprintf('Generating Randomized Prims proposals for %s\n', imname);
        proposals=calcrandomPrimForIm(im,rpconfig);
        saveFile=[imname '.mat'];
        save([config.outputLocation '/randomPrim/' saveFile], 'proposals');
end
