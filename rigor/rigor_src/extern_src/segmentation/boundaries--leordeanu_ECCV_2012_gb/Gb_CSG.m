% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% Gb Code Version 1
%--------------------------------------------------------------------------

% INPUT:  I - rgb color image

%--------------------------------------------------------------------------

% OUTPUT: 

%         gb_thin_CSG  - thin Gb boundaries using Color (C), Soft-segmentation (S) and Geometric grouping (G) 
%                        with nonlocal maxima suppression 
%         gb_thin_CS   - thin Gb boundaries using Color (C) and Soft-segmentation (S) 
%                        with nonlocal maxima suppression 
%         gb_CS        - continuous Gb boundaries using Color (C) and Soft-segmentation (S) 
%                        without nonlocal maxima suppression 
%
%         orC          - orientation computed from color channels, in
%                        degrees between 0 and 180
%
%         edgeImage      - color image with different pieces of contours in
%                          different colors; use it for visualization
%
%         edgeComponents - of the same size as I, with each contour having
%                          a unique integer assigned; a possible use is to find all
%                          pixels belonging to one contour 


% NOTE: gb_thin_CSG has better accuracy than gb_thin_CS

% This code is for research use only. 
% It is based on the following paper, which should be cited:

%  Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
%  in ECCV 2012

function [gb_thin_CSG, gb_thin_CS, gb_CS, orC, edgeImage, edgeComponents] = Gb_CSG(I)

[nRows, nCols, aux] = size(I);
imDiag = norm([nRows, nCols]);

wS = round(0.041*imDiag);
wC = round(0.016*imDiag);

alpha_AB = 1.9;

disp('soft-segmentation ...');

seg = softSegs(I);

disp('Gb: color + soft-segmentation ... ');

[gbC, orC] =  GbC_lambda(I, wC, alpha_AB);
[gbS, orS] =  Gb_data_lambda(seg, wS);

gb_CS = ni(gbC.*ni(gbS));

[gb_thin_CS, loc]  = nonmaxsup(gb_CS, orC, 2);

disp('contour reasoning ... ');

[gb_thin_CSG, edgeImage, edgeComponents] = Gb_geom(gb_thin_CS, orC);

end