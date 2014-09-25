% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% Gb Code Version 1
%--------------------------------------------------------------------------

% INPUT:  I - rgb color image

%--------------------------------------------------------------------------

% OUTPUT: 

%         gb_thin_CS   - thin Gb boundaries using Color (C) and Soft-segmentation (S) 
%                        with nonlocal maxima suppression 
%         gb_CS        - continuous Gb boundaries using Color (C) and Soft-segmentation (S) 
%                        without nonlocal maxima suppression 
%
%         orC          - orientation computed from color channels, in
%                        degrees between 0 and 180

% This code is for research use only. 
% It is based on the following paper, which should be cited:

%  Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
%  in ECCV 2012

function [gb_thin_CS, gb_CS, orC] = Gb_CS(I)

[nRows, nCols, aux] = size(I);
imDiag = norm([nRows, nCols]);

wS = round(0.041*imDiag);
wC = round(0.016*imDiag);

alpha_AB = 1.9;

seg = softSegs(I);

[gbC, orC] =  GbC_lambda(I, wC, alpha_AB);
[gbS, orS] =  Gb_data_lambda(seg, wS);

gb_CS = ni(gbC.*ni(gbS));

[gb_thin_CS, loc]  = nonmaxsup(gb_CS, orC, 2);

end