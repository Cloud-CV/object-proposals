function [pb1, pb2, theta] = getOrientedOcclusionProbs(bndinfo)
% [pb1, pb2, theta] = getOrientedOcclusionProbs(bndinfo)

if isstruct(bndinfo)
    bndinfo = bndinfo{1};
end

N = numel(bndinfo);
pocc = zeros([bndinfo{1}.imsize N], 'single');
pocc_left = zeros([bndinfo{1}.imsize N], 'single');

for k = 1:N
    
    tmpim = zeros(bndinfo{1}.imsize);
    tmpim1 = zeros(bndinfo{1}.imsize);
    
    if isfield(bndinfo{k}, 'result')
        pbk = 1-bndinfo{k}.result.edgeProb(:, 1);
        pbk1 = bndinfo{k}.result.edgeProb(:, 2) ./ pbk;
    elseif isfield(bndinfo{k}, 'pbnd')
        ne = bndinfo{k}.ne;
        pbk = 1-bndinfo{k}.pbnd(1:ne, 1);
        pbk1 = bndinfo{k}.pbnd(1:ne, 2) ./ pbk;
    else
        error('pb info not found')
    end
    

    for e = 1:bndinfo{k}.ne
        ind = bndinfo{k}.edges.indices{e};
        tmpim(ind(2:end-1)) = pbk(e); %tmpim(ind(2:end-1)) + pbk(e);
        tmpim(ind([1 end])) = max(tmpim(ind([1 end])), pbk(e)); % avoid overcounting junctions
        tmpim1(ind(1:end-1)) = pbk1(e); 
        %tmpim1(ind([1 end])) = tmpim1(ind([1 end])) + pbk1(e); % take average for junctions
    end   
    
    pocc(:, :, k) = tmpim;
    pocc_left(:, :, k) = tmpim1;
end

theta = bndinfo{1}.edges.thetaDirected;

% compute average pb for left and right side
ind = getBoundaryCenterIndices(bndinfo{1});
pb1 = mean(pocc.*pocc_left, 3);
pb1 = pb1(ind);
pb2 = mean(pocc.*(1-pocc_left), 3);
pb2 = pb2(ind);

