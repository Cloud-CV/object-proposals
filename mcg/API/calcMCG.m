function calcMCG( config )
%EDGEBOXES Summary of this function goes here
%   Detailed explanation goes here

mcgconfig = config.mcg;


% if(strcmp(ebconfig.database,'pascal2012') && ~exist(ebconfig.pascal2012path))
%     fprintf('Path to dataset pascal2012 does not exist. Please make sure you give a proper full path\n');
%     return; 
% end
% 
% if(strcmp(ebconfig.database,'bsds500') && ~exist(ebconfig.bsds500path))
%     fprintf('Path to dataset bsds500 does not exist. Please make sure you give a proper full path\n');
%     return; 
% end


%Check if image location exists or not.

if(~exist(mcgconfig.imageLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

if(~exist(mcgconfig.outputLocation, 'dir'))
	fprintf('Image Location does not exist. Please check path once again \n');
	return;
end

%Load All images in a particular folder
images = dir(mcgconfig.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

for i=1:length(images)
    imname = char(images(i));
    impath = strcat(mcgconfig.imageLocation, imname);
    whos impath
	im=imread(impath);
    
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	fprintf('Calculating MCG for %s\n', imname);
	[candidates, scores] = im2mcg(mcgconfig.root_dir, im, mcgconfig.opts.mode);

	saveFile=[imname '.mat'];
	save([mcgconfig.outputLocation saveFile], 'candidates', 'scores');
end

end

