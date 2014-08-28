function [featureScores]=mvg_computeFeatureScores(img,windows,config)
% function [featureScores]=mvg_computeFeatureScores(img,windows,config)
% computes feature scores for a given windows pointing to given image.
% See help of mvg_runObjectDetection.m for more details.
%
% Inputs:
% img, imgRow*imgCol*3, double, is the input color image. 
% windows, numWindows*4, double, is a matrix containing the examined 
%                                windows. Each row corresponds to one
%                                window in format:
%                                windows(i,:)=[xmin,ymin,xmax,ymax];
% config, struct, contains the parameter settings. See below for formatting 
%                 details. If undefined, default configuration will be used.
%
% Outputs:
% featureScores, numWindows*numFeatures, double, is a matrix containing the
%                                                feature scores for each 
%                                                window in windows input.
%                                                i:th row corresponds to i:th
%                                                row in window matrix.
%

% 2011 MVG, Oulu, Finland, Esa Rahtu and Juho Kannala 
% 2011 VGG, Oxford, UK, Matthew Blaschko

%% Default config
if nargin<3
    config.featureTypes={'SS','WS','BE','BI'}; % Feature to be computed from given windows
    config.verbose=1; %0->show nothing, 1->display progress
end

%% Initialize
numFeatures=length(config.featureTypes);
numWindows=size(windows,1);
featureScores=zeros(numWindows,numFeatures);

%% Loop over features
for i=1:numFeatures
    % Display
    if config.verbose>eps
        fprintf('Computing %s features...\n',config.featureTypes{i});
        intermediateTimeStamp=clock;
    end
    % Switch according to feature type
    switch config.featureTypes{i}
        % Superpixel straddling score 
        case 'SS'
            % Make sure superpixel representation exists
            if ~isfield(config,'superPixels')
                config.superPixels=mvg_computeSuperpixels(img);
            end
            
            % Compute SS score
            featureScores(:,i)=computeSSscore(config.superPixels, windows);
            
        % Window symmetry score
        case 'WS'
            % Compute WS scores
            featureScores(:,i)=mvg_windowsymmetryc_fast(img, windows);
            
        % Boundary edge distribution score    
        case 'BE'
            % Compute BE scores
            featureScores(:,i)=mvg_windowbec_fast(img, windows);
            
        % Superpixel boudary integral score    
        case 'BI'
            % Make sure superpixel representation exists
            if ~isfield(config,'superPixels')
                config.superPixels=mvg_computeSuperpixels(img);
            end
            
            % Compute BI scores
            featureScores(:,i)=mvg_superpixelBBintegralScore(config.superPixels, windows);
            
        otherwise
            error('Undefined features');
    end
    
    % Display
    if config.verbose>eps
        fprintf('%s features computed! Time taken %1.2f sec.\n',config.featureTypes{i},etime(clock,intermediateTimeStamp));
    end
    
end



