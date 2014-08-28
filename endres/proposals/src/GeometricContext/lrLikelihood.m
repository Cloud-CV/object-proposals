function p = lrLikelihood(x, w, y)

[ndata, nvar] = size(x);
x = [ones(ndata, 1) x];

if ~exist('y', 'var') || isempty(y)
    p = 1./(1+exp(-x*w));
else
    p = 1./(1+exp(y.*-(x*w)));
end