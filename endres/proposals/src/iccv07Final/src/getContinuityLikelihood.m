function [py, adjlist] = getContinuityLikelihood2(...
    X, bndinfo, c1, pC, dtCont, bndx)

if numel(c1)==1
    
    adjlist = bndinfo.edges.adjacency{c1};
    tx = getContinuityFeatures(X, bndinfo, c1, adjlist, pC, bndx);

    py = test_boosted_dt_mc(dtCont, tx);
    py = 1./(1+exp(-py));
    
    % normalize py for each source 
    %py = py / sum(py);
       
    
else

    nc = numel(c1);
    tx = cell(nc, 1);
    adjlist = cell(nc, 1);
    for k = 1:nc

        adjlist{k} = bndinfo.edges.adjacency{c1(k)}(:);        
        
        tx{k} = getContinuityFeatures(X, bndinfo, c1(k), adjlist{k}, pC, bndx);
        
        adjlist{k} = [repmat(c1(k), [numel(adjlist{k}) 1]) adjlist{k}];
        
    end
    
    tx = cat(1, tx{:});
    
    py = test_boosted_dt_mc(dtCont, tx);
    py = 1./(1+exp(-py));        
    
    % normalize py for each source
    if 0
    c = 0;
    for k = 1:numel(adjlist)
        nc2 = size(adjlist{k}, 1);
        py(c+1:c+nc2) = py(c+1:c+nc2) / sum(py(c+1:c+nc2));
        c = c + nc2;
    end
    end
    adjlist = cat(1, adjlist{:});
    
end
