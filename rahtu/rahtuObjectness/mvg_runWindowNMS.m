function [indexSelected]=mvg_runWindowNMS(windows,windowScores,config)
% function [indexSelected]=mvg_runWindowNMS(windows,windowScores,config)
% selects a set of windows from a larger set of candidate windows, based on
% window score and non maxima suppression. See help of 
% mvg_runObjectDetection.m for more details.
%
% Inputs:
% windows, numWindows*4, double, is a matrix containing the candidate 
%                                windows. Each row corresponds to one
%                                window in format:
%                                windows(i,:)=[xmin,ymin,xmax,ymax];
% windowScores, numWindows*1, double, is a vector of objectness scores associated
%                                     with each window in windowsOut. i:th entry
%                                     corresponds to i:th row in windowsOut.
% config, struct, contains the parameter settings. See below for formatting 
%                 details. If undefined, default configuration will be used.
%
% Outputs:
% indexSelected, numSelected*1, double, is an index vector pointing to the
%                                       selected windows in windows matrix.
%                                       Each element points to corresponding
%                                       row in windows matrix.
%

% 2011 MVG, Oulu, Finland, Esa Rahtu and Juho Kannala 
% 2011 VGG, Oxford, UK, Matthew Blaschko

%% Default configuration
if nargin<3
    config.NMStype='NMSab'; % The type of Non-Maximum-Suppression used
    config.numberOfOutputWindows=1000; % Number of output windows retuned
    config.numberOfIntermediateWindows=10001; % Number of windows after NMSa algorithm
    config.trhNMSa=0; % Threshold for NMSa method
    config.trhNMSb=0.75; % Threshold for NMSb method
end

%% Select according to NMS type
switch config.NMStype
    case 'NMSab'
        indexSamples1=mvg_selectWindowsNMSa(windows,windowScores,config.imageSize,config.numberOfIntermediateWindows,config.trhNMSa);
        indexSamples=selectWindowsNMSb_(windows(indexSamples1,:),windowScores(indexSamples1,:),config.numberOfOutputWindows,config.trhNMSb);
        indexSelected=indexSamples1(indexSamples);
        
    otherwise
        error('No other NMS options implemented');
end



%%%%%%%%%%%%%%%%%%%%%%%%
% Additional functions %
%%%%%%%%%%%%%%%%%%%%%%%%

%%% b-type NMS function %%%
function windowids=selectWindowsNMSb_(windows,scores,n,overlaplimit)

nw=length(scores);
[sscores,sid]=sort(scores(:),1,'descend');

swin=windows(sid,:);

ssids=selectwindows(swin(:,1),swin(:,2),swin(:,3),swin(:,4),n,overlaplimit);
windowids=sid(ssids);
