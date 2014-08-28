function [fig]=mvg_drawWindows(img,windows,fig)
% function [fig]=mvg_drawWindows(img,windows,numBest) draws the given windows
% on the given input image. 
%
% Inputs:
% img, imgRow*imgCol*1 or 3, double, is the input image.
% windows, numWindows*4, double, is a matrix containing the windows. 
%                                   Each row corresponds to one window in format:
%                                   windows(i,:)=[xmin,ymin,xmax,ymax];
% fig, 1*1, double, is a figure handle pointing to figure where image and
%                   windows are drawn. If not given, new figure will be
%                   created.
%
% Outputs:
% fig, 1*1, double, is a figure handle pointing to the figure where image
%                   and windows were drawn.
%

% 2011 MVG, Oulu, Finland, Esa Rahtu and Juho Kannala 
% 2011 VGG, Oxford, UK, Matthew Blaschko

%% User defined parameters
linewidth = 3;
base_color = [1 0 0];

%% Open figure if needed
if nargin<3
    fig=figure;
end

%% Draw image
figure(fig); clf;
imshow(img);

%% Draw windows
hold on;
for idx = 1:size(windows,1)
    plot(windows(idx,[1 3 3 1 1]),windows(idx,[2 2 4 4 2]),'Color',base_color,'linewidth',linewidth);
end







