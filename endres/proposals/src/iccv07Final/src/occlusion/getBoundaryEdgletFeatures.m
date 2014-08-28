function [x, featDescription] = getBoundaryEdgletFeatures(bndinfo, occ, varargin)
% [x, featDescription] = getBoundaryEdgletFeatures(bndinfo, occ, pb, pb2)

if 1
    ind = zeros(bndinfo{1}.ne,1);
    indices = bndinfo{1}.edges.indices;
    for k = 1:numel(ind)
        ind(k) = indices{k}(ceil(end/2));
    end
    [x, featDescription] = getBoundaryFeatures(ind, occ, varargin{:});
else
    N = numel(bndinfo);
    ne = bndinfo{1}.ne;
    x = zeros([ne N+1], 'single');

    for k = 1:N            
        if isfield(bndinfo{k}, 'result')
            x(:, k) = 1-bndinfo{k}.result.edgeProb(:, 1);
        elseif isfield(bndinfo{k}, 'pbnd')
            x(:, k) =  1-bndinfo{k}.pbnd(:, 1);
        end
        featDescription{k} = ['pocc' num2str(k)];
    end
    x(:, N+1) = max(x(:, 1:N), [], 2);
    featDescription{k+1} = 'pocc_max';
end