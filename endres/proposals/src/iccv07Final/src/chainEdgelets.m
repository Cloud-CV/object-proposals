function [chains, e2chain, chainsize] = chainEdgelets(pbVal, enext, thetaStart, ...
    thetaEnd, pbThresh, thetaThresh)
% chains = chainEdgelets(
%    pbVal, enext, thetaStart, thetaEnd, pbThresh, thetaThresh)
%
% Chains edglets with pbVal > pbThresh, such that the angle between
% consecutive fragments is always lower than thetaThresh.  
%
% pbVal(1:ne) - weight for each edge
% enext{1:ne}(1:nadj) - adjacent edges
% thetaStart(1:ne) - orientation at start of edgelet (deg)
% thetaEnd(1:ne) - orientation at end of edglet (deg)
% pbThresh - minimum edge weight
% thetaThresh - maximum discontinuity (deg)
%
% chains{nc}(:) - edge indices in each chain
% e2chain(1:ne) - maps edge index to chain index
% chainsize(1:nc) - length of each chain (in edgelets)


ne = numel(pbVal);

enext2 = cell(size(enext));
eprev = cell(size(enext));
ra = cell(size(enext));

for k = 1:numel(enext)
    enext{k} = enext{k}(:)';
end
thetaStart = thetaStart(:)';
thetaEnd = thetaEnd(:)';

nadj = 0;

for k = 1:numel(enext)
    
    % relative angle (absolute angle between two edgelets
    ra{k} = mod(abs(thetaEnd(k)-thetaStart(enext{k})), 180+1E-3);
         
    % remove adjacency if relative angle is greater than thetaThresh    

    ind = (ra{k} <= thetaThresh);    
    ra{k} = ra{k}(ind);
    enext2{k} = enext{k}(ind);   
    
    % create list of previous edgelets
    for k2 = enext2{k}
        eprev{k2}(end+1) = k;                        
    end           
    
    nadj = nadj + numel(enext2{k});
    
end

%disp(num2str(nadj/ne))

enext = enext2;

used = (pbVal < pbThresh);
nused = sum(used);

allind = (1:ne);

nc = 0;

chains = cell(sum(~used), 1);
chainsize = zeros(sum(~used), 1);
e2chain = zeros(ne, 1);

for start = 1:ne
    
    if ~used(start) && all(used(eprev{start}))

        nc = nc + 1;        

        k = start;
        chains{nc} = k;
        used(k) = true;
        nused = nused+1;        
        
        while 1
            next = enext{k}(~used(enext{k}));
            
            if isempty(next)
                break;
            elseif numel(next)>1
                [tmpval, nextid] = min(ra{k}(~used(enext{k})));
                next = next(nextid);
            end
            k = next;
            chains{nc}(end+1) = k;
            used(k) =true;
            nused = nused+1;
        end

        chainsize(nc) = numel(chains{nc});
        e2chain(chains{nc}) = nc;
        
    end
end
chainsize = chainsize(1:nc);
chains = chains(1:nc);
        
        
        
                