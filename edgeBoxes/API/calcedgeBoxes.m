function calcedgeBoxes( config )
ebconfig = config.edgeBoxes;

if(~exist([config.outputLocation '/edgeBoxes'], 'dir'))
        mkdir(config.outputLocation,'/dgeBoxes')
end

%Load All images in a particular folder
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

for i=1:length(images)
    imname = char(images(i));
    impath = fullfile(config.imageLocation, imname);
    im=imread(impath);   
    fprintf('Calculating Edge Boxes for %s\n', imname);
    proposals=calcedgeBoxesForIm(im,ebconfig);
    saveFile=[imname '.mat'];
    save([config.outputLocation '/edgeBoxes/' saveFile], 'proposals');
end

end

