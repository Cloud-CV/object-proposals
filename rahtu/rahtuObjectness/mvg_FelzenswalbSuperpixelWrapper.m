function [superPixSeg,superPixInd,superPixBounds]=mvg_FelzenswalbSuperpixelWrapper(img,sigma,min_area,k)
% The funtion [superPixSeg,superPixInd,superPixBounds]=FelzenswalbSuperpixels(img,sigma,min_area,k)
% is a wrapper funtion to superpixel segmentation algorithm from 
% Pedro F. Felzenszwalb and Daniel P. Huttenlocher, described in
% "Efficient Graph-Based Image Segmentation"
% Pedro F. Felzenszwalb and Daniel P. Huttenlocher
% International Journal of Computer Vision, 59(2) September 2004.
% The executables are available online in
% See http://www.cs.brown.edu/~pff/segment/
%

%% Path to executables of Felzenszwalb superpixel algorithm (see above)
global configjson
soft_dir=fullfile(configjson.rahtu.rahtuPath,'/segment/'); % Change here the path to the executables

%% Default parameters 
% Default parameters proposed by Felzenszwalb et al.  sigma = 0.5, k = 500, min_area = 20. (Larger values for k result in larger components in the result.)
if nargin<2
    sigma=0.5;
end
if nargin<3
    min_area=20;
end
if nargin<4
    k=500;
end

%% Initialize path
tmp_dir=soft_dir;
%tmp_dir=[soft_dir,'tmp',filesep];

%% Initialize files
tempFile=tempname(tmp_dir);
imgFile=[tempFile,'.ppm'];
segFile=[tempFile,'_superpix.ppm'];

% Make image file (in ppm format) if it does not exist already
if ~ischar(img)
    % Image matrix given, make ppm file
    imwrite(img,imgFile,'ppm');
    tempImage=1;
else
    % Image file name given (image has to be in ppm format, check)
    if ~strcmp(img(end-2:end),'ppm')
        error('If image file is given, it must be in ppm format');
    end
    imgFile=img;
    tempImage=0;
end


%% Run segmentation algorithm by Pedro F. Felzenszwalb and Daniel P. Huttenlocher
if isunix
    cmd = ['sh -c "unset LD_LIBRARY_PATH;' soft_dir 'segment ' num2str(sigma) ' ' num2str(k) ' ' num2str(min_area) ' "' imgFile '" "' segFile '""' ];
else
    cmd = [soft_dir 'segment ' num2str(sigma) ' ' num2str(k) ' ' num2str(min_area) ' ' imgFile ' ' segFile ];
end
system(cmd);

%% Read in segmentation result
superPixSeg=imread(segFile);

%% Return also index image if needed
if nargout>1
    superPixInd=mvg_numerizeLabels(superPixSeg);
end

%% Return also superpixel boundaries if needed
if nargout>2
    superPixBounds=superpixels2boundaries(superPixInd);
end

%% Delete temporary all created temporary files
if exist(imgFile,'file') && tempImage==1
    delete(imgFile);
end
if exist(segFile,'file')
    delete(segFile);
end










