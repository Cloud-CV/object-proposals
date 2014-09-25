% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% Gb Code Version 1
%--------------------------------------------------------------------------

% INPUT:  data      - image layers (any number) - they should be properly scaled
%         wSize     - window radius (2-4% of the image diagonal)
              

%--------------------------------------------------------------------------

% OUTPUT: 

%         gb_lambda   - continuous Gb boundaries 
%                       without the final logistic classifier and nonlocal maxima suppression; 
%                       it outputs the square root of the eigenvalue (norm of boundary height vector) 

%
%         or          - boundary orientation, in
%                       degrees between 0 and 180
%

% This code is for research use only. 
% It is based on the following paper, which should be cited:

%  Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
%  in ECCV 2012



function [gb_lambda, or] =  Gb_data_lambda(data, wSize)

%% LEARNED PARAMS -------------------------------------------------------

nDims = size(data,3);

% for i = 1:nDims
%     data(:,:,i) = w(i)*data(:,:,i);
% end

epsilon = 1;

%% INITIALIZATION ------------------------------------------------------------

nRows = size(data,1);
nCols = size(data,2);

wC =  wSize; %max(2, round(0.02*norm([nRows, nCols])));

nSamples_C = (2*wC+1)^2;

wgauss_C = fspecial('gaussian', [2*wC+1,2*wC+1], wC/(2*sqrt(2)));
wgauss_C = wgauss_C(:);

% ------------------------------------------
% ML ----------------------------------

aux1 = repmat(1:(2*wC+1), (2*wC+1),1 );
aux2 = aux1';

XP = [aux2(:), aux1(:)];
XP = XP - repmat(mean(XP), nSamples_C, 1);

normX = sqrt(sum(XP.^2,2));
ff = find(normX > epsilon);

XP(ff,:) = epsilon*XP(ff,:)./repmat(normX(ff),1,2);

XP(:,1) = wgauss_C.*XP(:,1);
XP(:,2) = wgauss_C.*XP(:,2);

ff2 = find(normX > wC);
XP(ff2,:) = 0;

auxMC = XP'/(sum(abs(XP(:,1))));

%%

t = reshape(auxMC, 2, 2*wC + 1, 2*wC + 1);
Gx = squeeze(t(1, :, :));
Gy = squeeze(t(2, :, :));

% keyboard;
%% get boundaries ---------------------------------------------------------

f1 =  1:(nRows*nCols);
ys = mod(f1-1,nRows)+1;
xs = floor(f1/nRows) + 1;

f2 = find(xs > wC & xs <= nCols - wC & ys > wC & ys <= nRows - wC);

xs = xs(f2);
ys = ys(f2);

f = f1(f2);

gb   = zeros(nRows*nCols,1);
or_C = zeros(nRows*nCols,2);

%alpha = 2.25; %weighs the importance of 'ab' (together) vs. 'L' in Lab space

resp_Ix = imfilter(data, Gx, 'symmetric');
resp_Iy = imfilter(data, Gy, 'symmetric');

resp_Ix = reshape(resp_Ix, nRows*nCols, nDims);
resp_Iy = reshape(resp_Iy, nRows*nCols, nDims);

Ms = zeros(nRows*nCols, 4);

for i = 1:nDims

    Ms(:, 1) = Ms(:, 1) + resp_Ix(:, i) .^2; %a
    Ms(:, 2) = Ms(:, 2) + resp_Ix(:, i) .* resp_Iy(:, i); %b=c
    Ms(:, 4) = Ms(:, 4) + resp_Iy(:, i) .^2; %d
    
end

Ms(:, 3) = Ms(:, 2); %b=c

T = Ms(:, 1) + Ms(:, 4);
D = Ms(:, 1) .* Ms(:, 4) - Ms(:, 2) .* Ms(:, 2);
f = find(Ms(:, 2) ~= 0);

gb(:) = Ms(:, 1);
gb(f) = T(f)/2 + sqrt((T(f) .^ 2 ) /4 - D(f));

or_C(:, 1) = 0;
or_C(f, 1) = -Ms(f, 2);
or_C(:, 2) = 1;
or_C(f, 2) = gb(f) - Ms(f, 1);


Norm = sqrt(or_C(:, 1) .^ 2 + or_C(:, 2) .^2);
or_C(:, 1) = or_C(:, 1) ./Norm;
or_C(:, 2) = or_C(:, 2) ./Norm;

gb_lambda = ni(reshape(sqrt(gb), nRows, nCols));

or_C = reshape(atan2(or_C(:,1), or_C(:,2)), nRows, nCols);
or_C(or_C<0) = or_C(or_C<0)+pi;            % Map angles to 0-pi.
or_C = or_C*180/pi;                        % Convert to degrees.

%[gb_thin, loc]  = nonmaxsup(gb, or_C, 2);  % non local max suppression
or = or_C;

return;
