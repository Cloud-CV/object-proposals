function [windows]=mvg_makeInitialWindows(img,config)
% function [windows]=mvg_makeInitialWindows(img,config) generates a set of
% initial proposal windows for given images. See help of 
% mvg_runObjectDetection.m for details.
%
% Inputs:
% img, imgRow*imgCol*3, double, is the input color image. 
% config, struct, contains the parameter settings. See below for formatting 
%                 details. If undefined, default configuration will be used.
%
% Outputs:
% windows, numWindows*4, double, is a matrix containing the candidate 
%                                windows. Each row corresponds to one
%                                window in format:
%                                windows(i,:)=[xmin,ymin,xmax,ymax];
%

% 2011 MVG, Oulu, Finland, Esa Rahtu and Juho Kannala 
% 2011 VGG, Oxford, UK, Matthew Blaschko


%% Default config
if ~exist('config','var') || isempty(config)
    % General
    config.windowTypes={'Prior','Superpix'}; % Methods for generating the initial windows (choises are {'Prior'},{'Random'},{'Prior','Superpix'} (default), and {'Random','Superpix'})
    config.numInitialWindows=100000; % The number of initial windows returned
    % Superpixel windows
    config.numberOfConnectedSuperpix=3; % The maximum number of connected superpixels
    % Prior windows
    config.windowPriorDistribution='ICCV_windowPriorDistribution.mat'; % mat-file or the structure containing the distribution of the prior windows
end

%% Initialize
config.imageSize=[size(img,1),size(img,2)];
windowCounter=0;
if length(config.windowTypes)>1 || ~strcmp(config.windowTypes{1},'Superpix')
    windows=zeros(config.numInitialWindows,4);
end
    

%% Make superpixel windows if needed
if sum(strcmp('Superpix',config.windowTypes))>eps
    % Compute superpixels (if not given in config.superPixels)
    if ~isfield(config,'superPixels')
        config.superPixels=mvg_computeSuperpixels(img);
    end

    % Make the superpixels windows (up to selected number of connected superpixels)
    windowsSuperpix=mvg_makeSuperpixelsWindows(config.superPixels,config.numberOfConnectedSuperpix);
    
    % Add windows to output
    if exist('windows','var')
        windows((windowCounter+1):(windowCounter+size(windowsSuperpix,1)),:)=windowsSuperpix;
    else
        windows=windowsSuperpix;
    end
    
    % Update counter
    windowCounter=windowCounter+size(windowsSuperpix,1);
end

%% Make rest of the needed windows from prior distribution (if configured to do so)
if sum(strcmp('Prior',config.windowTypes))>eps
    % Load prior distribution (if not given in config)
    if ~isstruct(config.windowPriorDistribution)
        load(config.windowPriorDistribution,'windowPriorDistribution');
        config.windowPriorDistribution=windowPriorDistribution;
    end
    
    % Sample needed amount of windows from prior
    windows((windowCounter+1):end,:)=mvg_samplePriorWindows(config.numInitialWindows-windowCounter,config.windowPriorDistribution,config.imageSize);
end

%% Make rest of the needed windows randomly (if configured to do so)
if sum(strcmp('Random',config.windowTypes))>eps
    % Make random coordinates (make user each window has width and height >=4 pixels
    numRandomWindows=config.numInitialWindows-windowCounter;
    xmin=round(rand(numRandomWindows,1)*(config.imageSize(2)-4))+1;
    ymin=round(rand(numRandomWindows,1)*(config.imageSize(1)-4))+1;
    xmax=xmin+3+round(rand(numRandomWindows,1)*(config.imageSize(2)-xmin-3));
    ymax=ymin+3+round(rand(numRandomWindows,1)*(config.imageSize(1)-ymin-3));

    % Store the coordinates
    windows((windowCounter+1):end,:)=[xmin ymin xmax ymax];
end

%% Make sure all windows are in integer coordinates
windows=round(windows);











