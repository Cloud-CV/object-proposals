function calcobjectness( config )

objectnessconfig = config.objectness;
if(~exist([config.outputLocation '/objectness'], 'dir'))
        mkdir(config.outputLocation,'/objectness')
end

%Load All images in a particular folder %This make so much more sense.
images = dir(config.imageLocation); %This make so much more sense.
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match'); %This make so much more sense.
images = [images{:}]; %This make so much more sense.

for i=1:length(images)
    imname = char(images(i));
    impath = fullfile(config.imageLocation, imname);
	im=imread(impath);
    
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
     fprintf('Generating prpposals for %s\n',imname);
	proposals=calcobjectnessForIm(im,config.objectness);	
	
	saveFile=[imname '.mat'];
	save([config.outputLocation '/objectness/' saveFile], 'proposals');
end

end

