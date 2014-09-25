% author: Marius Leordeanu
% last modified: October 2012

%--------------------------------------------------------------------------
% This basically is a helper function for Gb Soft-segmentation softSegs(),
% it returns a pool of soft forgraound/background segmentations
%--------------------------------------------------------------------------

% This code is for research use only. 
% It is based on the following paper, which should be cited:

%  Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
%  in ECCV 2012


function [Data, nDim] = getPCAData(Ihsv, param)

dW = param.dW;

dStep = param.dStep;
dimH = param.dimH;
dimS = param.dimS;
dimV = param.dimV;

[nRows, nCols, aux] = size(Ihsv);

%% pre process color info

%forground histogram
h = Ihsv(:,:,1);
s = Ihsv(:,:,2);

v = ni(Ihsv(:,:,3));

%transform into euclidean coordinates

% hx = (s.*cos(h*2*pi)+1)/2;
% hy = (s.*sin(h*2*pi)+1)/2;
% 
% h = ni(hx);
% s = ni(hy);

h = ni(h);
s = ni(s);

h = round(h*(dimH-1)+1);
v = round(v*(dimV-1)+1);
s = round(s*(dimS-1)+1);

im_col = h + (s-1)*dimH + (v-1)*dimH*dimS;

%% ----------------------------------------------------------------------

xs0 = (1+dW):8:(nCols-dW);
ys0 = ((1+dW):8:(nRows-dW))';

xs = repmat(xs0, length(ys0), 1);
ys = repmat(ys0, 1, length(xs0));

xs = xs(:);
ys = ys(:);

nPatches = length(xs);

X = zeros(nPatches, dimH*dimS*dimV);

for i = 1:nPatches

    c = im_col(ys(i)-dW:ys(i)+dW, xs(i)-dW:xs(i)+dW);

    X(i,c(:)) = 1;

end

%% learn PCA space of object color distributions

meanX = sum(X)/nPatches;

X = X - repmat(meanX, size(X,1), 1);

meanX = meanX';

M = X'*X;

[e,v] = eig(M);

v = diag(v);

energy = 0;

totalEnergy = sum(v);

nDim = 0;

while energy < 0.5*totalEnergy

    nDim = nDim + 1;
    energy = energy + v(length(v)-nDim+1);

end

e = e(:,size(M,1):-1:size(M,1)-(nDim-1));

%% generate possible segmentations ---------------------------------------

xs0 = (1+dW):dStep:(nCols-dW);
ys0 = ((1+dW):dStep:(nRows-dW))';

xs = repmat(xs0, length(ys0), 1);
ys = repmat(ys0, 1, length(xs0));

xs = xs(:);
ys = ys(:);

nTrials = length(xs);

Data  = zeros(nRows*nCols, nTrials);

for i = 1:nTrials

    x0  = xs(i);
    y0  = ys(i);

    auxI = im_col(y0-dW:y0+dW, x0-dW:x0+dW);

    c = zeros(dimH*dimS*dimV,1);

    c(auxI(:)) = 1;

    c = c - meanX;

    c1  = meanX;
    c0  = meanX;

    for k = 1:nDim

        coef = c'*e(:,k);

        c1 = c1 + coef*e(:,k);

        c0 = c0 - coef*e(:,k);

    end

    c1(c1 < 0) = 0;
    c0(c0 < 0) = 0;

    Data(:, i) = c1(im_col(:))./(c1(im_col(:)) + c0(im_col(:)) + eps);
    
end

return

