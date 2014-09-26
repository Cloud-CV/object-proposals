
% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% Gb Code Version 1
%--------------------------------------------------------------------------

%
% given an edge map, with values between 0 and 1, it quickly produces edges
% with higher quality strenght based on edge linking and contour features 
% 
% it also outputs the linked contours found 

% INPUT:  gb - any thin boundary/edge map with values in the 0 to 1 range
%         or - boundary orientation in degrees (between 0 to 180)
%              (it probably works with values in 0 to 360, didn't check)

%--------------------------------------------------------------------------

% OUTPUT: 

%         gb_geom       - probablility of boundary using local and contour
%                         features (using both geometry and boundary strength)
%                         (values in gb_geom are more accurate than in the input gb)


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

function [gb_geom, edgeImage, edgeComponents] = Gb_geom(gb, or)

or_orig = or;
th = 0.10;
maxDist = 10;
[nRows, nCols] = size(gb);

aux = zeros(size(gb));
aux(1:maxDist, :) = 1;
aux(nRows-maxDist:nRows, :) = 1;
f = find(aux);
or = or*pi/180;
h = abs(cos(or));
f2 = find(h(f) < th);
gb_thin2 = gb;
gb_thin2(f(f2)) = 0;

aux = zeros(size(gb));
aux(:,nCols-maxDist:nCols) = 1;
aux(:,1:maxDist) = 1;
f = find(aux);
v = abs(sin(or));
f2 = find(v(f) < th);
gb_thin2(f(f2)) = 0;
gb = gb_thin2;

%% ------------------------------------------------

b_geom = [1.8706   -2.9498   -1.5891]';
b_Gb = [3.5048,   -1.1067-0.5958,  -3.0846-0.4972, -0.7805-6.0588]';
bAll = [2.8851 -1.6519 -4.3131]';

[feat, gbHard, edgeImage, edgeComponents] = linkEdges(gb, or_orig);

f = find(gbHard);
nP = length(f);

X = ones(nP, 3);
X(:,2) = feat{1}(f);
X(:,3) = feat{2}(f);

out_1 = 1./(1 + exp(X*b_geom));

X = ones(nP, 4);

for i = 2:4
    X(:,i) = feat{i+1}(f);   
end

out_2 = 1./(1 + exp(X*b_Gb));

X = ones(nP, 3);
X(:,2) = out_1;
X(:,3) = out_2;

out = 1./(1 + exp(X*bAll));

gb_geom = gb;
gb_geom(f) = out;

end
