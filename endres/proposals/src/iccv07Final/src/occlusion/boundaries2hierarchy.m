function hier = boundaries2hierarchy(pB, spLR, cost_method, norm, wseg, cost)

% [result, valdata, dispim] = mergeMinSafe(pB, bndinfo, X, maxProb, minRegions, DO_VAL)
%
% Note that (as oppoosed to mergeMin) edges here are undirected.  Also,
% when new edgelets are created, their likelihoods are re-evaluated to
% ensure that they do not increase.  maxProb is the maximum probability an
% edge can have to *not* be removed.
% spLR(i, [1 2]) gives the left and right, resp., 

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

if isempty(DO_DISPLAY)
    DO_DISPLAY = 0;
end

ne = numel(pB);
nsp = max(spLR(:));

if ~exist('wseg', 'var')
    wseg = [];
end

if ~exist('cost', 'var')
    cost = pB;
end

MAX = 1;
MEAN = 2;
MIN = 3;
SOFTMAX = 4;
NORM = 2;
switch lower(cost_method)
    case 'max'
        cost_method = MAX;
    case 'mean'
        cost_method = MEAN;
    case 'min'
        cost_method = MIN;
    case 'softmax'
        cost_method = SOFTMAX;
        if ~isempty(norm), NORM = norm; end
    otherwise
        error(['invalid cost_method: ' cost_method]);
end

echain = num2cell(1:ne);  % edgelet chain between each pair of regions
rsp = num2cell(1:nsp);
validr = true(nsp, 1);
e2chain = (1:ne);

% unite borders between two superpixels that are split
reme = [];
spLRm = zeros([nsp nsp], 'uint16');
for k = 1:ne  
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

%% Iteratively merge regions

Ecost = zeros(numel(echain), 1);
for k = 1:numel(echain)
    if cost_method==MEAN
        Ecost(k) = mean(pB(echain{k}));
    elseif cost_method==MAX
        Ecost(k) = max(pB(echain{k}));
    elseif cost_method==MIN
        Ecost(k) = min(pB(echain{k}));
    elseif cost_method==SOFTMAX
        Ecost(k) = sum(pB(echain{k}).^NORM)^(1/NORM);          
    end    
end

nregions = nsp;
nedges = numel(echain);

hier.init_cost = zeros(nsp, 1);
for k = 1:nsp
    hier.init_cost(k) = min(Ecost((spLR(:, 1)==k) | (spLR(:, 2)==k)));
end
hier.new_index = zeros(nsp-1, 1);
hier.new_region = cell(nsp-1, 1);
hier.edges_removed = cell(nsp-1, 1);
hier.thresh = zeros(nsp-1, 1);
hier.old_index = zeros(nsp-1, 1);
hier.cost = zeros(nsp-1, 1);

iter = 0;
while nregions > 1
    
    iter = iter + 1;                           
    
    [mincost, minind] = min(Ecost);
            
    keep = true(nedges, 1);
    reme = minind;
    keep(minind) = false;
    
    r1 = spLR(minind, 1);
    r2 = spLR(minind, 2);
    
    minchain = echain{minind};
    
    newr = r1;  
    
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
                if cost_method==MEAN
                    Ecost(i1) = mean(pB(echain{i1}));
                elseif cost_method==MAX
                    Ecost(i1) = max(pB(echain{i1}));
                elseif cost_method==MIN
                    Ecost(i1) = min(pB(echain{i1}));
                elseif cost_method==SOFTMAX
                    Ecost(i1) = sum(pB(echain{i1}).^NORM)^(1/NORM);        
                end    
            end
        end
    end

       
    % remove extra edges, regions
    validr(r2) = false;        
    
    rsp{newr} = [rsp{r1} rsp{r2}];           
    
    hier.new_index(iter) = newr;
    hier.new_region{iter} = rsp{newr};
    hier.thresh(iter) = mincost;
    hier.old_index(iter) = r2;
    hier.edges_removed{iter} = minchain;
    
    if cost_method==MEAN
        hier.cost(iter) = mean(cost(minchain));
    elseif cost_method==MAX
        hier.cost(iter) = max(cost(minchain));
    elseif cost_method==MIN
        hier.cost(iter) = min(cost(minchain));
    elseif cost_method==SOFTMAX
        hier.cost(iter) = (sum(cost(minchain)).^NORM)^(1/NORM);          
    end       
    %hier.scores(iter) = 
    
    echain = echain(keep);
    spLR = spLR(keep, :);
    Ecost = Ecost(keep);
    
    e2chainshift = max(cumsum(keep),1);
    e2chain = e2chainshift(e2chain);
    
    nregions = nregions - 1;
    nedges = numel(Ecost);
    
    if DO_DISPLAY && mod(iter, 500)==0    
        displayRegions(rsp(validr), wseg, 1);                
    end      
    
end

hier.regions = cat(1, num2cell((1:nsp)'), hier.new_region);






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