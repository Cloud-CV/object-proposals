function [BIscores]=mvg_superpixelBBintegralScore(superpixels, windows, config)

%% Default settings
if nargin<3
    config.probDist='Gaussian'; % 'Dist' 'Gaussian' 'DistGaussian'
    config.GaussSigma=3;
    config.exponent=2;
    config.dilate=3;
    config.verbose=4;
end

%% Find bounding boxes and make boundary mask image
lbs=unique(superpixels);
numSpix=length(lbs);
spixBox=zeros(numSpix,4);
for i=1:numSpix
    [rw,cl]=find(superpixels==lbs(i));
    spixBox(i,:)=[min(cl),min(rw),max(cl),max(rw)];
end

%% Make boundary mask
boundaryMask=zeros(size(superpixels));
for i=1:numSpix
    boundaryMask(spixBox(i,2):spixBox(i,4),spixBox(i,1))=1;
    boundaryMask(spixBox(i,2):spixBox(i,4),spixBox(i,3))=1;
    boundaryMask(spixBox(i,2),spixBox(i,1):spixBox(i,3))=1;
    boundaryMask(spixBox(i,4),spixBox(i,1):spixBox(i,3))=1;
end

%% Dilate
if config.dilate>0
    structEl=strel('disk',config.dilate);
    boundaryMask=imdilate(boundaryMask,structEl);
end

%% Make distance transform based probability
switch config.probDist
    case 'Dist'
        probFun=1-bwdist(boundaryMask);
        probFun=(probFun-min(probFun(:)))/max((probFun(:)-min(probFun(:))));
        probFun=probFun.^config.exponent;
    case 'Gaussian'
        GaussianFun=makeGaussian_(config.GaussSigma*[1 1]);
        probFun=conv2(double(boundaryMask),GaussianFun,'same');
    case 'DistGaussian'
        probFun=1-bwdist(boundaryMask);
        probFun=(probFun-min(probFun(:)))/max((probFun(:)-min(probFun(:))));
        probFun=probFun.^config.exponent;
        GaussianFun=makeGaussian(config.GaussSigma*[1 1]);
        probFun=conv2(double(probFun),GaussianFun,'same');
    otherwise
        error('Unknown method');
end

%% Integrate over window borders to get BI score
BIscores=integrateOverWindowBorder_(probFun,windows);




%%%%%%%%%%%%%%%%%%%%%%%%
% Additional functions %
%%%%%%%%%%%%%%%%%%%%%%%%


%%% Integrate over the windows border %%%
function [windowIntegral,winMeasure]=integrateOverWindowBorder_(probFun,windows)

%% Initialize 
if size(windows,2)>4
    windows=windows(:,1:4);
end
numWindow=size(windows,1);
intLineImg=zeros(size(probFun,1),size(probFun,2),2);
windowIntegral=zeros(numWindow,1);

%% Form line integral image
intLineImg(:,:,1)=cumsum(probFun,1); % Row sums
intLineImg(:,:,2)=cumsum(probFun,2); % Column sums
intLineImg=[zeros(size(intLineImg,1),1,2),intLineImg]; % Add zero column
intLineImg=[zeros(1,size(intLineImg,2),2);intLineImg]; % Add zero row

%% If given windows are in normalized coordinates, denormalize them
if max(windows(:))<1.000001
    imgCol=size(probFun,2);
    imgRow=size(probFun,1);
    windows(:,[1,3])=windows(:,[1,3])*(imgCol-1)+1;
    windows(:,[2,4])=windows(:,[2,4])*(imgRow-1)+1;
end

%% Round windows to integer coordinates
windows=max(round(windows(:,1:4)),1);

%% Loop over windows and compute bounding box scores
for i=1:numWindow
    % Get critical points
    Xmin=windows(i,1);
    Ymin=windows(i,2);
    Xmax=windows(i,3);
    Ymax=windows(i,4);
    
    % Compute sums (start each one pixel further to avoid taking corners twice)
    topSum=intLineImg(Ymin+1,Xmax+1,2)-intLineImg(Ymin+1,Xmin+1,2);
    bottomSum=intLineImg(Ymax+1,Xmax+1,2)-intLineImg(Ymax+1,Xmin+1,2);
    leftSum=intLineImg(Ymax+1,Xmin+1,1)-intLineImg(Ymin+1,Xmin+1,1);
    rightSum=intLineImg(Ymax+1,Xmax+1,1)-intLineImg(Ymin+1,Xmax+1,1);
    %% For reference the full sums, which count corner points twice
    %topSum=intLineImg(Ymin+1,Xmax+1,2)-intLineImg(Ymin+1,Xmin,2);
    %bottomSum=intLineImg(Ymax+1,Xmax+1,2)-intLineImg(Ymax+1,Xmin,2);
    %leftSum=intLineImg(Ymax+1,Xmin+1,1)-intLineImg(Ymin,Xmin+1,1);
    %rightSum=intLineImg(Ymax+1,Xmax+1,1)-intLineImg(Ymin,Xmax+1,1);

    % Assing sum over bounding box to window score
    windowIntegral(i)=topSum+bottomSum+leftSum+rightSum;
    
end

%% If two output arguments are required, return also box size and edge length
if nargin>1
    boxWidth=windows(:,3)-windows(:,1)+1;
    boxHeight=windows(:,4)-windows(:,2)+1;
    
    winMeasure.Perimeter=2*boxWidth+2*boxHeight-4; % Need to subtract extra corners (that's why -4)
    winMeasure.Area=boxWidth.*boxHeight;
end

%%% Make Gaussian funtion %%%
function [GaussianFun]=makeGaussian_(GaussianSigma,WindowRadius)

%% Return trivial case
if min(GaussianSigma)<eps
    GaussianFun=1;
    return;
end

%% Default settings
if nargin<2
    %WindowRadius=max(round(2*GaussianSigma),1);
    WindowRadius=round(2*GaussianSigma);
end
   
%% Initialize
dim=length(GaussianSigma); % How many dimensions in output Gaussian (3D is max and ordering is row, column, and third dimension).
GaussianSigma=2*GaussianSigma.^2; %Turn sigma from standard deviation to variance (2* is to include 1/(2*sigma^2) already here).
% If only one value for size is given and more dimensions are required, use same size for all dimensions.
if length(WindowRadius)==1 && dim>1
    WindowRadius=WindowRadius(1)*ones(1,dim);
end

%% Generate Gaussian function to the required dimensions
if dim==1
    d1=-WindowRadius(1):WindowRadius(1); % spatial coordinates   
    GaussianFun=exp(-((d1.^2)/GaussianSigma(1))); % Gaussian values
    
elseif dim==2
    [d2,d1]=meshgrid(-WindowRadius(2):WindowRadius(2),-WindowRadius(1):WindowRadius(1)); % spatial coordinates 
    GaussianFun=exp(-((d1.^2)/GaussianSigma(1)+(d2.^2)/GaussianSigma(2))); % Gaussian values

elseif dim==3
    [d2,d1,d3]=meshgrid(-WindowRadius(2):WindowRadius(2),-WindowRadius(1):WindowRadius(1),-WindowRadius(3):WindowRadius(3)); % spatial coordinates     
    GaussianFun=exp(-((d1.^2)/GaussianSigma(1)+(d2.^2)/GaussianSigma(2)+(d3.^2)/GaussianSigma(3))); % Gaussian values
    
else
    error('Not implemented');
end

%% Normalize data to have sum equal to fun.
GaussianFun=GaussianFun/sum(GaussianFun(:));






