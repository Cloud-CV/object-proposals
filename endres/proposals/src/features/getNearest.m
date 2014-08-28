function idx = getNearest(data, centers,trans)
% idx = getNearest(data, centers)
%
% Gets indices of centers closest (in Euclidean space) to each data point
%
% data(ndata, nvars)
% centers(ncenters, nvars)
% idx(ndata, 1)

% dist(a, b) = ||a-b|| = sum(a.^2) - 2*a*b' + sum(b.^2) for 1xnvars vectors
% a and b.  

if(~exist('trans','var'))
    centers = centers';
end
centerssq = sum(centers.^2, 1);
    
distmat = repmat(centerssq, [size(data,1) 1]);
distmat = distmat - 2*data * centers;

[dist, idx] = min(distmat, [], 2);

