function calcEndres( config )
%EDGEBOXES Summary of this function goes here
%   Detailed explanation goes here

endresconfig = config.endres;

%Load All images in a particular folder
images = dir(endresconfig.imageLocation);
images = regexpi({images.name}, '.*jpg|.*jpeg|.*png|.*bmp', 'match');
images = [images{:}];

for i=1:length(images)
    imname = char(images(i));
    impath = strcat(endresconfig.imageLocation, imname);
    whos impath
	im=imread(impath);
    
	if(size(im, 3) == 1)
		im=repmat(im,[1,1,3]);
	end
	fprintf('Calculating Endres for %s\n', imname);
	rankedProposals = generate_proposals(im);
   
	saveFile=[imname '.mat'];
	save([endresconfig.outputLocation saveFile], 'rankedProposals');
end

end

