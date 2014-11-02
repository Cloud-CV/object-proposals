function calcmcg( config )
rmpath(genpath([pwd '/dependencies/structuredEdges/release']));
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

if(~exist([config.outputLocation '/mcg'], 'dir'))
        mkdir(config.outputLocation,'/mcg')
end

for i=1:length(images)
    imname = char(images(i));
    impath = fullfile(config.imageLocation, imname);
    im=imread(impath);
    
    fprintf('Calculating MCG proposasls for %s\n', imname);
    proposals=calcmcgForIm(im,config.mcg);
    saveFile=[imname '.mat'];
    save([config.outputLocation '/mcg/' saveFile], 'proposals');
end
addpath(genpath([pwd '/dependencies/structuredEdges/release']));
end

