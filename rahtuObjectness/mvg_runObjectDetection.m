function [windowsOut,scoreOut]=mvg_runObjectDetection(img,config)
% function [windowsOut,scoreOut]=mvg_runObjectDetection(img,config)
% returns a set of candidate windows which are prominent to contain 
% objects over broad variety of classes.
%
% Inputs:
% img, imgRow*imgCol*3, double, is the input color image.
% config, struct, contains the parameter settings. See below for formatting 
%                 details. If undefined, default configuration will be used.
%
% Outputs:
% windowsOut, numWindows*4, double, is a matrix containing the candidate 
%                                   windows. Each row corresponds to one
%                                   window in format:
%                                   windowsOut(i,:)=[xmin,ymin,xmax,ymax];
% scoreOut, numWindows*1, double, is a vector of objectness scores associated
%                                 with each window in windowsOut. i:th entry
%                                 corresponds to i:th row in windowsOut.
%
% Example usage:
% >>img=imread('exampleImage.jpg');
% >>[windowsOut,scoreOut]=mvg_runObjectDetection(img);
% >>mvg_drawWindows(img,windowsOut((1:10),:));

% This program implements the method described in:
%
% Rahtu E. & Kannala J. & Blaschko M. B. 
% Learning a Category Independent Object Detection Cascade. 
% Proc. International Conference on Computer Vision (ICCV 2011).

% 2011 MVG, Oulu, Finland, Esa Rahtu and Juho Kannala 
% 2011 VGG, Oxford, UK, Matthew Blaschko

%% Default configuration (for details, please refer to the paper above)
% The parameters you most likely need to change are config.NMS.numberOfOutputWindows that
% defines the number of output windows and config.NMS.trhNMSb, which defines the non-maxima
% suppression threshold (0.4-0.6 gives better recall with lower overlaps, 0.6-> gives better reall with high overlaps).
if ~exist('config','var') || isempty(config)
    %% Initial window sampling parameters
    % General
    config.InitialWindows.loadInitialWindows=false; % false->nothing is loaded, true->load initial windows from the file given in storage parameter below (overrides all other initial window settings)
    config.InitialWindows.windowTypes={'Prior','Superpix'}; % Methods for generating the initial windows
    config.InitialWindows.numInitialWindows=100000; % The number of initial windows returned
    % Superpixel windows
    config.InitialWindows.numberOfConnectedSuperpix=3; % The maximum number of connected superpixels used with the initial windows
    % Prior windows
    config.InitialWindows.windowPriorDistribution='ICCV_windowPriorDistribution.mat'; % mat-file or the structure containing the distribution of prior windows

    %% Feature parameters
    config.Features.loadFeatureScores=false; % false->nothing is loaded, true->load feature scores from the file given in storage parameter below (overrides all other initial feature settings)
    config.Features.featureTypes={'SS','WS','BE','BI'}; % Feature to be computed from initial windows
    config.Features.featureWeights=[1.685305e+00, 7.799898e-02, 3.020189e-01, -7.056292e-04]; % Relative feature weights (same ordering as with the features above)
    
    %% NMS parameters
    config.NMS.NMStype='NMSab'; % The type of Non-Maximum-Suppression used
    config.NMS.numberOfOutputWindows=1000; % Number of output windows retuned
    config.NMS.numberOfIntermediateWindows=10001; % Number of windows after NMSa algorithm
    config.NMS.trhNMSa=0; % Threshold for NMSa method
    config.NMS.trhNMSb=0.75; % Threshold for NMSb method
    
    %% Storage parameters (file names with full path, set empty if nothing will be stored or loaded)
    config.Storage.initialWindows=[];
    config.Storage.features=[];
    config.Storage.outputWindows=[];
    
    %% General parameters
    config.verbose=0; % 0->show nothing, 1->display progress 
end

%% Initialize
% General
timeStamp=clock;
config.Features.verbose=config.verbose;
config.NMS.imageSize=[size(img,1),size(img,2)];

% Check loading paramets
if config.Features.loadFeatureScores && ~config.InitialWindows.loadInitialWindows
    error('If you load feature scores, also corresponding windows must be loaded. Otherwise windows and scores do not match!');
end

% Ensure superpixel representation exists if it is needed anywhere in the algorithm 
if (sum(strcmp('Superpix',config.InitialWindows.windowTypes))>eps && ~config.InitialWindows.loadInitialWindows) || ((sum(strcmp('SS',config.Features.featureTypes))>eps || sum(strcmp('BI',config.Features.featureTypes))) && ~config.Features.loadFeatureScores)
    % Compute superpixels if they are not in config.superPixels
    if ~isfield(config,'superPixels')
        % Display
        if config.verbose>eps
            fprintf('\nComputing superpixels...\n');
            intermediateTimeStamp=clock;
        end
        % Compute superpixels
        config.superPixels=mvg_computeSuperpixels(img);
        % Display
        if config.verbose>eps
            fprintf('Superpixels computed! Time taken %1.2f sec.\n',etime(clock,intermediateTimeStamp));
        end
    end
    % Store superpixels for initial windows and feature scoring
    config.InitialWindows.superPixels=config.superPixels;
    config.Features.superPixels=config.superPixels;
end

%% Load or make initial windows 
if config.InitialWindows.loadInitialWindows
    % Display
    if config.verbose>eps
        fprintf('\nLoading initial windows from:\n%s...\n',config.Storage.initialWindows);
    end
    
    % Load data
    load(config.Storage.initialWindows,'windows','configInitialWindows');

    % Reset initial window config
    config.InitialWindows=configInitialWindows;
    
else
    % Display
    if config.verbose>eps
        fprintf('\nCreating initial windows...\n');
        intermediateTimeStamp=clock;
    end
    % Make windows
    windows=mvg_makeInitialWindows(img,config.InitialWindows);
    % Display
    if config.verbose>eps
        fprintf('Initial windows done! Time taken %1.2f sec.\n',etime(clock,intermediateTimeStamp));
    end
    % Store initial windows
    if ~isempty(config.Storage.initialWindows)
        % Display
        if config.verbose>eps
            fprintf('Storing initial windows to:\n%s\n',config.Storage.initialWindows);
        end
        % Store initial windows
        configInitialWindows=config.InitialWindows;
        save(config.Storage.initialWindows,'windows','configInitialWindows');
    end
end


%% Load or compute feature scores 
if config.Features.loadFeatureScores
    % Display
    if config.verbose>eps
        fprintf('\nLoading feature scores from:\n%s...\n',config.Storage.features);
    end
    
    % Load data
    load(config.Storage.features,'featureScores','configFeature');
    
    % Reset initial window config
    config.Features=configFeature;
    
else
    % Display
    if config.verbose>eps
        fprintf('\nComputing feature scores...\n');
        intermediateTimeStamp=clock;
    end
    % Run score computation
    featureScores=mvg_computeFeatureScores(img,windows,config.Features);
    % Display
    if config.verbose>eps
        fprintf('Features computed! Time taken %1.2f sec.\n',etime(clock,intermediateTimeStamp));
    end
    % Store feature scores
    if ~isempty(config.Storage.features)
        % Display
        if config.verbose>eps
            fprintf('Storing feature scores to:\n%s\n',config.Storage.features);
        end
        % Store feature scores
        configFeature=config.Features;
        save(config.Storage.features,'featureScores','configFeature');
    end
end


%% Make combined score
% Display
if config.verbose>eps
    fprintf('\nComputing combined scores...\n');
    intermediateTimeStamp=clock;
end
% Compute linear combination
combinedScores=(config.Features.featureWeights*featureScores')';
% Display
if config.verbose>eps
    fprintf('Combined score computed! Time taken %1.2f sec.\n',etime(clock,intermediateTimeStamp));
end

%% Run NMS to get indices to selected windows
% Display
if config.verbose>eps
    fprintf('\nSelecting final output windows...\n');
    intermediateTimeStamp=clock;
end
% Run NMS
selectedId=mvg_runWindowNMS(windows,combinedScores,config.NMS);
% Display
if config.verbose>eps
    fprintf('Final windows selected! Time taken %1.2f sec.\n',etime(clock,intermediateTimeStamp));
end

%% Take selected window coordinates and scores
windowsOut=windows(selectedId,:);
if nargout>1
    scoreOut=combinedScores(selectedId);
end
% Store output windows
if ~isempty(config.Storage.outputWindows)
    % Display
    if config.verbose>eps
        fprintf('Storing output windows to:\n%s\n',config.Storage.outputWindows);
    end
    % Store feauture scores
    save(config.Storage.outputWindows,'windowsOut','scoreOut','config');
end


%% Print done
if config.verbose>eps
    fprintf('Done!\n');
    fprintf('Total time taken: %1.2f sec.\n',etime(clock,timeStamp));
end



