function calcRigor( config )
%RIGOR Summary of this function goes here
%   Detailed explanation goes here

rigorconfig = config.rigor;
param = rigorconfig.params.param_set;

%Check if image location exists or not.

if(~exist(config.imageLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

if(~exist(config.outputLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

%Load All images in a particular folder
images = dir(config.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

for i=1:length(images)
    imname = char(images(i));
    impath = fullfile(config.imageLocation, imname);
    whos impath
    im=imread(impath);
    fprintf('Calculating RIGOR for %s\n', imname);
    proposals =calcrigorForIm(impath,rigorconfig); 
    saveFile=[imname '.mat'];
    save([config.outputLocation saveFile], 'proposals');
end
end

