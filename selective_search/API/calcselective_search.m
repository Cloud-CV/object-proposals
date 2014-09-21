function calcselective_search( config)
ssconfig = config.selective_search;
    
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];
if(~exist([config.outputLocation '/selective_search'], 'dir'))
	mkdir(config.outputLocation,'/selective_search')
end
    
for i=1:length(images)
        imname = char(images(i));
        
        fprintf('Calculating Selective Search Object Proposals for %s\n', imname);
        
        impath = fullfile(config.imageLocation, imname);
        im=imread(impath);
        
        
        proposals=calcselective_searchForIm(im,ssconfig);
        saveFile=[imname '.mat'];
        save([config.outputLocation '/selective_search/' saveFile], 'proposals');
end
  

