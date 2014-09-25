% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% Gb Code Version 1
%--------------------------------------------------------------------------

% function: links edges into contours

% INPUT:  gb - any thin boundary/edge map with values in the 0 to 1 range
%         or - boundary orientation in degrees (between 0 to 180)
%              (it probably works with values in 0 to 360, didn't check)

%--------------------------------------------------------------------------

% OUTPUT: 

%         feat       - contour features

%         gbHard     - binary edge map

%         edgeImage      - color image with different pieces of contours in
%                          different colors; use it for visualization
%
%         edgeComponents - of the same size as I, with each contour having
%                          a unique integer assigned; a possible use is to find all
%                          pixels belonging to one contour 

% This code is for research use only. 
% It is based on the following paper, which should be cited:

%  Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
%  in ECCV 2012


function [feat, gbHard, edgeImage, edgeComponents] = linkEdges(gb, or)

% 
% or = or*pi/180;
% 
% or = atan2(-sin(or), cos(or));
% or(or<0) = or(or<0)+pi;            % Map angles to 0-pi.
% or = or*180/pi;                    % Convert to degrees.

%% Thresholds

% angle_sigma = 3; 
% angleThresh = 30;
% nradius = 1.5;

T1 = 0.01;
T2 = 0.18; 

%% get different gbs ...

gbHard = hysthresh(gb, T1, T2);
gb1 = gb.*gbHard; 

%% imresize

[nRows, nCols] = size(gb);

mSize = max([nRows, nCols]);

nradius = 1.5; 
angle_sigma  = 3; 
angleThresh1 = 30;

const_sigma  = 9*angle_sigma^2;
angleThresh2 = 3*angle_sigma;

%% Preprocessing

ind_edge = find(gbHard);

x_edge = floor((ind_edge - 1)/nRows) + 1; 
y_edge = mod(ind_edge - 1, nRows) + 1;

nEdges = length(ind_edge);

mapEdges = zeros(nRows, nCols);
mapEdges(ind_edge) = 1:nEdges;

max_entries = 300000;

spc_i_indices   = zeros(max_entries, 1);
spc_j_indices   = zeros(max_entries, 1);
spc_affinities  = zeros(max_entries, 1);

components =  1:nEdges;

n_nz = 0;

idx = zeros(nRows,nCols);
idx((x_edge-1)*nRows + y_edge) = [1:nEdges];


%% connect edges based on smoothness and build matrix M

%disp(' building the matrix '); 

for i = 1:nEdges
               
    [locs, dist, index] = getNeighbors3([y_edge, x_edge],[y_edge(i), x_edge(i)], idx, nradius);
          
    nNeighbors = length(index);
   
    for j = 1:nNeighbors
       
        if index(j) <= i
            continue;
        end
      
        %% a1
        
        diff1 = mod(abs(or(y_edge(i), x_edge(i)) - or(locs(j,1), locs(j,2))), 180);
    
        angle_diff1 = min(180 - diff1, diff1); 
        
        if angle_diff1 > angleThresh1
            continue;
        end
             
        n_nz = n_nz + 1;
        
        spc_i_indices(n_nz)  = i;
        spc_j_indices(n_nz)  = index(j);
        
        if angle_diff1 < angleThresh2
            aSum = 1  - (angle_diff1^2)/const_sigma;
        else
            aSum = eps;
        end
        
        if aSum < 0
            keyboard;
        end
            
        spc_affinities(n_nz) = aSum;
        
        %connect these edges into components
        
        c_i = getComponent(components, mapEdges(y_edge(i), x_edge(i)));
        c_j = getComponent(components, mapEdges(locs(j,1), locs(j,2)));
        
        if c_i > c_j
            components(c_i) = c_j;
        else
            components(c_j) = c_i;
        end
        
    end
    
end

%finish up the connected components stuff

for i=1:nEdges
    components(i) = getComponent(components, i);
end

n_nz = n_nz + 1;

spc_i_indices(n_nz)  = nEdges;
spc_j_indices(n_nz)  = nEdges;
spc_affinities(n_nz) = 0;

% disp('nr of non-zero elements ');
% n_nz

spc_i_indices = spc_i_indices(1:n_nz);
spc_j_indices = spc_j_indices(1:n_nz);
spc_affinities = spc_affinities(1:n_nz);

M = spconvert([spc_i_indices spc_j_indices spc_affinities]);
M = M + M';

%% compute contours properties

n = size(M,1);

u_comp = unique(components);

compSize = ones(n,1);
avgGeom  = zeros(n,1);

avggb = zeros(n,1);
maxgb = zeros(n,1);

for  i = 1:length(u_comp)
   
    f = find(components == u_comp(i));
    
    compSize(f) = length(f);
    avgGeom(f) = 0.5*sum(sum(M(f,f)))/length(f);
       
    avggb(f) = mean(gb1(ind_edge(f)));        
    maxgb(f) = max(gb1(ind_edge(f)));    
     
end

feat = [];

di = norm([nRows, nCols]);

compSize(compSize > di) = di;
compSize = compSize/di;

% contour geometric values

feat{1} = zeros(nRows, nCols);
feat{1}(ind_edge) = compSize;

feat{2} = zeros(nRows, nCols);
feat{2}(ind_edge) = avgGeom;

% gb edge values

feat{3} = zeros(nRows, nCols);
feat{3}(ind_edge) = avggb;

feat{4} = zeros(nRows, nCols);
feat{4}(ind_edge) = maxgb;

feat{5} = zeros(nRows, nCols);
feat{5}(ind_edge) = gb1(ind_edge);

%% ---------------------------------------------------------------------

edgeImage = zeros(nRows, nCols,3);

f = 1:n; 

nColors = length(u_comp);
c = 0.2 + 0.6*rand(nColors, 3);

lambda_color = zeros(max(u_comp),1);
lambda_color(u_comp) = 1:nColors;

colors = c(lambda_color(components(f)),:);

temp = zeros(nRows, nCols);

temp(ind_edge(f)) = colors(:,1);
edgeImage(:,:,1) = temp;

temp(ind_edge(f)) = colors(:,2);
edgeImage(:,:,2) = temp;

temp(ind_edge(f)) = colors(:,3);
edgeImage(:,:,3) = temp;


edgeComponents = zeros(nRows, nCols);
edgeComponents(ind_edge) = components;


return

%% auxiliary function used for the connected components algorithm

function i = getComponent(comp, i)

while comp(i) ~= i
    
    i = comp(i);
    
end

return