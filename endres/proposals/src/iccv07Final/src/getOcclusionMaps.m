function pocc = getOcclusionMaps(bndinfo)

if isstruct(bndinfo)
    bndinfo = bndinfo{1};
end

N = numel(bndinfo);
pocc = zeros([bndinfo{1}.imsize N], 'single');

for k = 1:N
    
    tmpim = zeros(bndinfo{1}.imsize);
    
    if isfield(bndinfo{k}, 'result')
        pbk = 1-bndinfo{k}.result.edgeProb(:, 1);
    elseif isfield(bndinfo{k}, 'pbnd')
        pbk = 1-bndinfo{k}.pbnd(:, 1);
    else
        error('pb info not found')
    end
    
    for e = 1:bndinfo{k}.ne
        ind = bndinfo{k}.edges.indices{e};
        tmpim(ind(2:end-1)) = pbk(e); %tmpim(ind(2:end-1)) + pbk(e);
        tmpim(ind([1 end])) = max(tmpim(ind([1 end])), pbk(e)); % avoid overcounting junctions
    end   
    
    pocc(:, :, k) = tmpim;
    
end

