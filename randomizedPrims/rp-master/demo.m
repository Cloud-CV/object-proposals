%% Paths
addpath('matlab');
addpath('cmex');

%% Global variables (needed for callbacks)
global h imgId files imgDir configFile;

%% Input
imgDir = 'test_images';
imgId = 1;
configFile = 'config/rp.mat'; 
%'config/rp_4segs.mat' to sample from 4 segmentations (slower but higher recall)
%'config/rp.mat' to sample from 1 segmentations (faster but lower recall)

%% Find images in dir:
files = dir(imgDir);
assert(numel(files) >= 3);
files = files(3 : end);
if(strcmp(files(1).name, '.svn'))
  files = files(2 : end);
end

%% Figure initialization:
close all;
h = figure(1);
set(h, 'Menubar', 'none')
set(h, 'WindowButtonMotionFcn', @WindowButtonMotionCallback);
set(h, 'WindowButtonDownFcn', @WindowButtonDownFcnCallback);

%% Processing:
InteractiveCenterDemo(configFile);

