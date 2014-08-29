function [featureScores]=mvg_computeSSscore(superPixels,windows)
%
% The function implements the SS feature developed and described by
% Alexe B., Deselaers T. & Ferrari V. (2010) 
% What is an object? 
% Proc The IEEE Conference on Computer Vision and Pattern Recognition (CVPR).
% 

 
% Compute integral histogram image from superpixels
integralHist=integralHistSuperpixels_(superPixels);

% Get areas for superpixels and windows
areaSuperpixels=hist(superPixels(:),1:max(superPixels(:)));
areaWindows=(windows(:,3) - windows(:,1) + 1) .* (windows(:,4) - windows(:,2) + 1);

% Initialize superpixel intersection matrix
intersectionSuperpixels=zeros(length(windows(:,1)),size(integralHist,3));

% Compute intersections
for dim = 1:size(integralHist,3)
    intersectionSuperpixels(:,dim)=computeIntegralImageScores_(integralHist(:,:,dim),windows);
end

% Compute SS score from intersections
featureScores=ones(size(windows,1),1)-(sum(min(intersectionSuperpixels,repmat(areaSuperpixels,size(windows,1),1) - intersectionSuperpixels),2)./areaWindows);


%%%%%%%%%%%%%%%%%%%%%%%%
% Additional functions %
%%%%%%%%%%%%%%%%%%%%%%%%

%%% Compute integral histograms of superpixels %%%
function integralHist = integralHistSuperpixels_(superpixels)

% Initialize
superpixels = int16(superpixels);
numSuperpix = max(superpixels(:));
[height width] = size(superpixels);
integralHist = zeros(height+1,width+1,numSuperpix);

% Loop over superpixels and make integral histogram images
for i = 1:numSuperpix   
    integralHist(:,:,i) = computeIntegralImage_(superpixels==i);
end

%%% Compute integral image %%%
function integralImage = computeIntegralImage_(table)

integralImage = cumsum(table,1); 
integralImage = cumsum(integralImage,2);
[height width] = size(table);
%set the first row and the first column 0 in the integral image
integralImage =[zeros(height,1) integralImage];
integralImage=[zeros(1,width+1); integralImage];



%%% Compute integral image scores %%%
function score = computeIntegralImageScores_(integralImage,windows)

windows = round(windows);
height = size(integralImage,1);
index1 = height*windows(:,3) + (windows(:,4) + 1);
index2 = height*(windows(:,1) - 1) + windows(:,2);
index3 = height*(windows(:,1) - 1) + (windows(:,4) + 1);
index4 = height*windows(:,3) + windows(:,2);
score = integralImage(index1) + integralImage(index2) - integralImage(index3) - integralImage(index4);

