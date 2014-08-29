function [windows]=mvg_samplePriorWindows(numWindowSample,windowPriorDistribution,imageSize)

%% Read histograms
winHeight2winWidth=windowPriorDistribution.winHeight2winWidth;
winHeight2Ycent=windowPriorDistribution.winHeight2Ycent;
winWidth2Xcent=windowPriorDistribution.winWidth2Xcent;

%% Read bin numbers
numBinXcent=windowPriorDistribution.numBinXcent;
numBinYcent=windowPriorDistribution.numBinYcent;
numBinHeight=windowPriorDistribution.numBinHeight;
numBinWidth=windowPriorDistribution.numBinWidth;

%% Make bin centers
binStepXcent=1/numBinXcent;
binStepYcent=1/numBinYcent;
binStepWinHeight=1/numBinHeight;
binStepWinWidth=1/numBinWidth;
binCentXcent=(binStepXcent/2):binStepXcent:(1-binStepXcent/2);
binCentYcent=(binStepYcent/2):binStepYcent:(1-binStepYcent/2);
binCentWinHeight=(binStepWinHeight/2):binStepWinHeight:(1-binStepWinHeight/2);
binCentWinWidth=(binStepWinWidth/2):binStepWinWidth:(1-binStepWinWidth/2);

%% Sample window height and width from 2D distribution
linSampleIndex=mvg_scoreSamplingWrapper(winHeight2winWidth(:),numWindowSample);
heightIndex=mod(linSampleIndex-1,size(winHeight2winWidth,1))+1;
widthIndex=(linSampleIndex-heightIndex)/size(winHeight2winWidth,1)+1;
windowScore=winHeight2winWidth(linSampleIndex);

%% Sample y centers
yCentIndex=zeros(numWindowSample,1);
for i=1:numBinHeight
    ii=heightIndex==i;
    numSmpl=sum(ii);
    if numSmpl>eps
        sampleIndex=mvg_scoreSamplingWrapper(winHeight2Ycent(i,:),numSmpl);
        yCentIndex(ii)=sampleIndex;
        windowScore(ii)=windowScore(ii).*winHeight2Ycent(i,sampleIndex);
    end
end

%% Sample x centers
xCentIndex=zeros(numWindowSample,1);
for i=1:numBinWidth
    ii=widthIndex==i;
    numSmpl=sum(ii);
    if numSmpl>eps
        sampleIndex=mvg_scoreSamplingWrapper(winWidth2Xcent(i,:),numSmpl);
        xCentIndex(ii)=sampleIndex;
        windowScore(ii)=windowScore(ii).*winWidth2Xcent(i,sampleIndex);
    end
end

%% Map indices to values
winHeight=binCentWinHeight(heightIndex);
winWidth=binCentWinWidth(widthIndex);
xCent=binCentXcent(xCentIndex);
yCent=binCentYcent(yCentIndex);

%% Transform to other coordinate for
yMin=yCent-winHeight/2;
yMax=yCent+winHeight/2;
xMin=xCent-winWidth/2;
xMax=xCent+winWidth/2;
windows=[xMin(:),yMin(:),xMax(:),yMax(:)];

%% Make sure windows stay in image area
windows(windows<0)=0;
windows(windows>1)=1;

%% Denormalize windows if image size is given
if exist('imageSize','var')
    windows(:,[1 3])=(windows(:,[1 3])*(imageSize(2)-1))+1;
    windows(:,[2 4])=(windows(:,[2 4])*(imageSize(1)-1))+1;
end