function [result, valdata, dispim] = ...
    mergeMinSafe(pB, bndinfo, X, dtFast, maxProb, minRegions, DO_VAL)
% [result, valdata, dispim] = mergeMinSafe(pB, bndinfo, X, maxProb, minRegions, DO_VAL)
%
% Note that (as oppoosed to mergeMin) edges here are undirected.  Also,
% when new edgelets are created, their likelihoods are re-evaluated to
% ensure that they do not increase.  maxProb is the maximum probability an
% edge can have to *not* be removed.

%% Initialize edge and region information
% for each edgelet store:
%     adjacent edgelets, pairwise energy with adjacent edgelets, whether
%     the edgelet is on (all on initially), minimum "on" energy, "off"
%     energy
%
% for each region store:
%     which other regions it is adjacent to
%     the set of superpixels in each region
%
% for each pair of adjacent regions store:
%     edgelet list connecting them 
%     current cost of merging

global DO_DISPLAY;

if ~exist('DO_VAL', 'var')
    DO_VAL = 0;    
end

if isempty(DO_DISPLAY)
    DO_DISPLAY = 0;
end

if DO_VAL
    nval = 0;
    valstep = 10; %floor(bndinfo.nseg / 100);
    stats = regionprops(bndinfo.wseg, 'Area');
    areas = cat(1, stats(:).Area);
    segError = zeros(bndinfo.nseg, 1);
    mergeCost = zeros(bndinfo.nseg, 1);    
    numRegions = zeros(bndinfo.nseg, 1);
else
    valdata = [];
end

ne = bndinfo.ne;
nsp = bndinfo.nseg;
wseg = bndinfo.wseg;

% spLR(i, [1 2]) gives the left and right, resp., 
spLR = bndinfo.edges.spLR;

% edge adjacency: i-->enext{i}(j)
% enext = bndinfo.edges.adjacency;
% for k1 = 1:ne
%     enext{k1} = [enext{k1}(:)' enext{k1+ne}(:)'];
%     enext{k1} = enext{k1}(enext{k1}<=ne);
% end

echain = num2cell(1:ne);  % edgelet chain between each pair of regions
rsp = num2cell(1:nsp);
validr = true(nsp, 1);
e2chain = (1:ne);
needsUpdating = false(ne, 1);

% unite borders between two superpixels that are split
reme = [];
spLRm = zeros([nsp nsp], 'uint16');
for k = 1:ne
    %s1 = spLR(k, 1);  s2 = spLR(k, 2);
    s1 = min(spLR(k, :));  s2 = max(spLR(k,:));
    if spLRm(s1,s2)==0
        spLRm(s1,s2) = k;
    else
        reme(end+1) = k;
        k2 = spLRm(s1, s2);
        echain{k2} = [echain{k2} echain{k}];        
        e2chain(echain{k2}) = k2;
    end
end
spLR(reme, :) = [];
echain(reme) = [];
e2chainshift = ones(numel(e2chain), 1);
e2chainshift(reme) = 0;
e2chainshift = cumsum(e2chainshift);
e2chain = e2chainshift(e2chain);
clear spLRm

pB = 1-pB(1:ne, 1); % probability of edge being on

%% Iteratively merge regions

Ecost = zeros(numel(echain), 1);
for k = 1:numel(echain)
    Ecost(k) = max(pB(echain{k}));    
end

nregions = nsp;
nedges = numel(echain);

%disp(num2str(nedges));

iter = 0;
while nregions > minRegions
    
    iter = iter + 1;                           
    
    done = 0;
    while ~done
        [mincost, minind] = min(Ecost);    
        done = 1;
        if needsUpdating(minind)
            r1 = rsp{spLR(minind, 1)};
            r2 = rsp{spLR(minind, 2)};
            eid = echain{minind};
            tx = updateFastBoundaryClassifierFeatures(X, r1, r2, eid);
            conf = test_boosted_dt_mc(dtFast, double(tx));
            conf = 1 / (1+exp(-conf));            
            needsUpdating(minind) = false;
            if conf > mincost
                done = 0;
                Ecost(minind) = max(conf, Ecost(minind));
            end
        end
    end
                    
    if mincost >= maxProb
        break;
    end
    
    if DO_VAL && mod(iter-1, valstep)==0        
        nval = nval + 1;
        nsp = max(wseg(:));
        segError(nval) = ...
            getSegmentationErrorFast(bndinfo.labels, nsp, rsp(validr), areas);
        mergeCost(nval) = mincost;
        numRegions(nval) = nregions;
    end    
    
    if DO_DISPLAY && mod(iter, 500)==0    
                
        %disp(num2str([iter nregions nedges mincost]));
        
        displayRegions(rsp(validr), bndinfo.wseg, 1);        
        
        if 0
        nstr = num2str(100000 + iter);
        imwrite(tmpim, ['./tmp/merging' nstr(2:end) '.jpg']);        
        end
        
        %movframe(iter/25) = im2frame(tmpim);        
%        movframe(iter/25) = getframe(1);
    end     

    keep = true(nedges, 1);
    reme = minind;
    keep(minind) = false;
    
    r1 = spLR(minind, 1);
    r2 = spLR(minind, 2);
    
    newr = r1;
    
%     ok = 0;
%     for k = 1:size(spLR, 1)
%          if (any(ismember(rsp{spLR(k, 1)}, 342)) && any(ismember(rsp{spLR(k, 2)}, 226))) || ...
%                  (any(ismember(rsp{spLR(k, 2)}, 342)) && any(ismember(rsp{spLR(k, 1)}, 226)))
%             ok = 1;
%          end
%     end
%     if ~ok
%         keyboard;
%     end    
    
    % get neighbors to left and right of r1 and r2
    ind1L = find(spLR(:, 1)==r1);    
    ind2L = find(spLR(:, 1)==r2);  
    left1 = spLR(ind1L, 2);
    left2 = spLR(ind2L, 2);    
    ind1R = find(spLR(:, 2)==r1);
    ind2R = find(spLR(:, 2)==r2);
    right1 = spLR(ind1R, 1);
    right2 = spLR(ind2R, 1);     

    spLR([ind1L ; ind2L], 1) = newr;    
    spLR([ind1R ; ind2R], 2) = newr;        
    
%     disp(num2str(['iter: ' num2str([iter   log(mincost)-log(1-mincost)])]));
%     disp(num2str(rsp{r1}))
%     disp(num2str(rsp{r2}))
%     disp(num2str(log(mincost) - log(1-mincost)))
%     
%     if iter==15
%         keyboard;
%     end
    
    % unite any split borders that may arise
    indL = [ind1L ; ind2L ; ind1R ; ind2R]';  
    s1 = [left1 ; left2 ; right1 ; right2]';      
    for k1 = 1:numel(s1)
        for k2 = k1+1:numel(s1)
            if s1(k1)==s1(k2) && ~any(reme==indL(k2))                
                keep(indL(k2)) = false;                                
                i1 = indL(k1);
                echain{i1} = [echain{i1} echain{indL(k2)}];
                e2chain(echain{i1}) = i1;
                Ecost(i1) = max(pB(echain{i1}));
                %needsUpdating(i1) = true;                                
            end
        end
    end
    needsUpdating(indL) = true;
    
%     ok = 0;
%     for k = 1:size(spLR, 1)
%          if (any(ismember(rsp{spLR(k, 1)}, 357)) && any(ismember(rsp{spLR(k, 2)}, 226))) || ...
%                  (any(ismember(rsp{spLR(k, 2)}, 357)) && any(ismember(rsp{spLR(k, 1)}, 226)))
%             ok = 1;
%          end
%     end
%     if ~ok
%         keyboard;
%     end
%     indR = [ind1R; ind2R]';  
%     s1 = [right1 ; right2]';  
%     for k1 = 1:numel(s1)
%         for k2 = k1+1:numel(s1)
%             if s1(k1)==s1(k2) && ~any(reme==indR(k2))                
%                 keep(indR(k2)) = false;
%                 i1 = indR(k1);
%                 echain{i1} = [echain{i1} echain{indR(k2)}];
%                 e2chain(echain{i1}) = i1;
%                 Ecost(i1) = max(pB(echain{i1}));
%                 needsUpdating(i1) = true;                                
%             end
%         end
%     end               
    
    % remove extra edges, regions
    validr(r2) = false;        
    
    rsp{newr} = [rsp{r1} rsp{r2}];    
    
%     tmp = zeros(nsp, 1);
%     validind = find(validr);
%     for k = 1:numel(validind)
%         tmp(rsp{validind(k)}) = k;
%     end
%     if any(tmp==0)
%         keyboard;
%     end
    
    
    echain = echain(keep);
    spLR = spLR(keep, :);
    Ecost = Ecost(keep);
    needsUpdating = needsUpdating(keep);
    
%     if any(spLR(:, 1)==spLR(:, 2))
%         keyboard;
%     end
    
    e2chainshift = max(cumsum(keep),1);
    e2chain = e2chainshift(e2chain);
    
    nregions = nregions - 1;
    nedges = numel(Ecost);
    
end

%movie2avi(movframe, './tmp/merging.avi')

rshift = cumsum(validr);
spLR= rshift(spLR);

result.edgeletChain = echain;
result.chainLR = spLR;
result.regions = rsp(validr);

if DO_VAL
    valdata.mergeCost = mergeCost(1:nval);
    valdata.segError = segError(1:nval);
    valdata.nregions = numRegions(1:nval);
end

if DO_DISPLAY || (nargout > 2)
    dispim = displayRegions(result.regions, bndinfo.wseg, DO_DISPLAY);
end




%% Display function
function tmpim = displayRegions(rsp, wseg, fignum)

nsp = max(wseg(:));

elab = zeros(nsp, 1);
for k = 1:numel(rsp)
    elab(rsp{k}) = k;
end  

tmpim = label2rgb(elab(wseg));
[tx, ty] = gradient(elab(wseg));
te = tx~=0 | ty~=0;
tmpim(repmat(te, [1 1 3])) = 0;

if fignum > 0
    figure(fignum), hold off, imagesc(tmpim), axis image, drawnow;
end