
% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% Gb Soft-segmentation Code Version 1
%--------------------------------------------------------------------------

% INPUT:  I - rgb color image

%--------------------------------------------------------------------------

% OUTPUT: 

%   seg   - soft segmentation of the image I of dimension [nRows, nCols, 8];
%           each channel is obtained by PCA compression along the first eigenvectors dimensions 
%           of a pool of soft foreground/background segmentations

% This code is for research use only. 
% It is based on the following paper, which should be cited:

%  Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
%  in ECCV 2012


function seg  = softSegs(I)

%disp(' soft segmentation ... :) ');

param.dW = 8;
param.dStep = 30;

param.dimH  = 15;  
param.dimS  = 11;  
param.dimV  = 7;   

param.medfilt = 1;
param.ni = 1;
param.wFilt = 9;

maxSize = 300;

%% -----------------------------------------------------------------------

[nRows, nCols, aux] = size(I);

%% -------------------------------------

I = double(I);

I(:,:,1) = ni(I(:,:,1));
I(:,:,2) = ni(I(:,:,2));
I(:,:,3) = ni(I(:,:,3));

I = uint8(255*I);

I2 = imresize(I, maxSize/max([nRows, nCols]));    

[nRows2, nCols2, m] = size(I2);

Ihsv = rgb2hsv(I2);

[Data, nDims] = getPCAData(Ihsv, param);

%% ---------------------------------------

k = 8;

Data = single(Data);

Data2 = (Data - repmat(mean(Data), nRows2*nCols2, 1));
M = Data2'*Data2;

[v,d] = eig(M);

v = v(:,size(M,1):-1:(size(M,1) - k + 1));

seg2 = reshape(Data2*v(:,1:k), nRows2, nCols2, k);

seg = zeros(nRows, nCols, size(seg2,3));

for i = 1:k
    
    seg(:,:,i) = imresize(seg2(:,:,i), [nRows, nCols]);
    
    if param.medfilt == 1
        seg(:,:,i) = medfilt2(seg(:,:,i), [param.wFilt, param.wFilt]);
    end
    
end

if param.ni == 1
    seg = ni(seg);
end

end