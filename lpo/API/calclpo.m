function calclpo( config )
lpoconfig = config.lpo;
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

if(~exist([config.outputLocation '/lpo'], 'dir'))
    mkdir(config.outputLocation,'/lpo')
end
for i=1:length(images)
        imname = char(images(i));
        impath = fullfile(config.imageLocation, imname);
        im=imread(impath);

        if(size(im, 3) == 1)
            im=repmat(im,[1,1,3]);
        end

        fprintf('Generating LPO Proposals for %s\n', imname);
        proposals=calclpoForIm(im,lpoconfig);
        saveFile=[imname '.mat'];
        save([config.outputLocation '/lpo/' saveFile], 'proposals');
end