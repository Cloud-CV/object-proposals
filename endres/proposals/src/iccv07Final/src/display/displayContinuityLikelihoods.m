function [pcim, pcim2, pim] = displayContinuityLikelihoods(dtBnd, dtCont, bndinfo, X, Y)

ne = bndinfo.ne;

pC = useBoundaryClassifier(X, dtBnd, 'c');

pim = zeros(size(bndinfo.wseg));
for k = 1:ne
    pim(bndinfo.edges.indices{k}) = 1 - min(pC(k,1), pC(k+ne,1));
end

pim = ordfilt2(pim,9,ones(3,3));

figure(1), imagesc(pim), colorbar, axis image, colormap gray


%% Get conditionals for true boundaries
pcim = zeros(size(bndinfo.wseg));
ind = find(Y > 0);
for k = 1:numel(ind)

    type = Y(ind(k));    
    [py, adj] = getContinuityLikelihood(X, bndinfo, ind(k), pC, type, dtCont);
   
    adj = mod(adj-1, ne)+1;
    
    for k2 = 1:numel(adj)    
        pcim(bndinfo.edges.indices{adj(k2)}) = py(k2);        
    end
    
end

pcim = ordfilt2(pcim,9,ones(3,3));

figure(2), imagesc(pcim, [0 1]), colorbar, axis image, colormap gray

%% Get conditionals for false boundaries
pcim2 = zeros(size(bndinfo.wseg));
ind = find((Y(1:ne) == 0) & (Y(ne+1:2*ne)==0));
for k = 1:numel(ind)
    type = ceil(rand(1)*5);    % choose random type    
    [py, adj] = getContinuityLikelihood(X, bndinfo, ind(k), pC, type, dtCont);  
    adj = mod(adj-1, ne)+1;    
    for k2 = 1:numel(adj)    
        pcim2(bndinfo.edges.indices{adj(k2)}) = py(k2);        
    end    
end

pcim2 = ordfilt2(pcim2,9,ones(3,3));

figure(3), imagesc(pcim2, [0 1]), colorbar, axis image, colormap gray

