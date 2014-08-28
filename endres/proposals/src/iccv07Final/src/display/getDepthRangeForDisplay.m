function [imdepthMin, imdepthMax, imdepthCol, contact, x, y, z] = ...
    getDepthRangeForDisplay(bndinfo, glabels, elabels, dt, v0)
% getMinimumDepth(bndinfo, glabels, v0)
%
% Minimum depth is the depth of the foremost occluder.  Maximum depth is
% the depth of the current region, assuming that it is touching ground at
% its lowest point.  If a region is in the foreground, it's minimum depth
% may be a function, and the minimum depth is equal to the maximum depth.
% Otherwise, the minimum and maximum depths are single (different) values.
%
% log(Z) = log(f*y_c) - log(v_0-v_i)

global DO_DISPLAY;

%% Get depth ordering

ordering = occlusion2depthOrdering(bndinfo, elabels, glabels);

%% Set some parameters

MIN_HV_DIST = 0.01;  % minimum distance between horizon and object contact 
SKY_DEPTH = 2*(1 ./ MIN_HV_DIST);


%% Get pixel images for ground, vertical, and sky
labim = glabels(bndinfo.wseg);
vim = labim==2;
gim = labim==1;
sim = labim==3;

[imh, imw] = size(vim);

%% Make sure that horizon is above ground and below sky
scol = sum(sim, 2)>0;
gcol = sum(gim, 2)>0;
v0 = (1-v0) * imh;

try
minv = find(scol);  minv = minv(end-1);
maxv = find(gcol);  maxv = maxv(2);

if v0 < minv || v0 > maxv
    if minv > maxv
        v0 = maxv-1;
    else
        v0 = maxv-imh/20;
    end
end
%disp(num2str([v0 maxv minv]))
catch
end

v0 = 1 - v0/imh;
%disp(num2str(v0))

%figure(1), imagesc(cat(3, vim, gim, sim)), axis image


%% Get possible ground-vertical boundary pixels

stats = regionprops(bndinfo.wseg, 'BoundingBox', 'PixelIdxList');
bbox = vertcat(stats.BoundingBox);
idx = {stats.PixelIdxList};

% bbox = [x1 y1 x2 y2]
bbox = [bbox(:, 1) bbox(:, 2) bbox(:, 1)+bbox(:,3) bbox(:,2)+bbox(:,4)];

vfilt = [ones(3, 1) ; zeros(3, 1)];
gfilt = 1-vfilt; 
boundaryim = (imfilter(double(vim), vfilt)==sum(vfilt(:))) & ...
    (imfilter(double(gim), gfilt)==sum(gfilt(:)));
boundaryim(end, :) = vim(end, :);
boundaryim = imdilate(boundaryim, ones(3, 1));

%figure(3), imagesc(boundaryim), axis image


bpts = cell(bndinfo.nseg, 1);
edges = bndinfo.edges.indices;
spLR = bndinfo.edges.spLR;
eim = zeros(bndinfo.imsize);
for k = 1:numel(edges)
    sp1 = spLR(k, 1);
    sp2 = spLR(k, 2);
    bndind = edges{k}(boundaryim(edges{k}));
    if ~isempty(bndind)
        if glabels(sp1)==2 % && glabels(sp2)==1
            bpts{sp1} = [bpts{sp1} ; bndind];
        elseif glabels(sp2)==2 % && glabels(sp1)==1
            bpts{sp2} = [bpts{sp2} ; bndind];
        end
    end
    eim(edges{k}) = 1;
end


%% Get a simple estimate of depth (trace columns upwards)

imdepthCol = zeros(bndinfo.imsize(1:2));
maxg = imh*ones(1, imw);
for y = imh:-1:1
    maxg(gim(y, :)) = y;
    imdepthCol(y, :) = maxg;
end
%imy = repmat((1:imh)', [1 imw]);
% imdepthCol = log(1 ./ max(v0 - (imh-imdepthCol)/imh, MIN_HV_DIST));
% imdepthCol(sim==1) = log(SKY_DEPTH);
for k = 1:numel(idx)
    imdepthCol(k) = (imh-median(imdepthCol(idx{k})))/imh;
end
% if DO_DISPLAY
%     figure(3), imagesc(imdepthCol), axis image
% end


%% Get the depth of each object that has a ground boundary

bx = zeros(numel(bpts), 2);
by = zeros(numel(bpts), 2);
bz = zeros(numel(bpts), 2);
bzmin = zeros(numel(bpts), 2);
bzmax = zeros(numel(bpts), 2);
isvalid = false(numel(bpts), 1);
for k = 1:numel(bpts)
    if numel(bpts{k})>5 || bbox(k, 4)+1>=imh
        
        [py, px] = getPerimeter(bndinfo, k, 50);
        bx(k, :) = bbox(k, [1 3]);
        
        cu = [];  cv = [];
        if  1 %bx(k, 2)-bx(k, 1) > imw/10  % only get line for larger objects
                 
            
            keep = true(size(px));
            for tk = 1:numel(px)
                if ~any(boundaryim(py(tk) + imh*(px(tk)-1)))
                    keep(tk) = false;
                end
            end
            %px = px(keep);  py = py(keep);                  
            
            %if k==13, keyboard; end
            
            try 
                [cu, cv] = poly2contacts(dt, px, py, bndinfo.imsize, v0, 1.7, [], 0.1);
            catch
            end
            %plot(cu, cv, 'r*')
            cu = round(cu);  cv = round(cv);
            ind = (boundaryim(cv + (cu-1)*imh)); % | (cv==max(cv));
            cu = cu(ind);  cv = cv(ind);  
        end        
        
        [cu, ind] = unique(cu);
        cv = cv(ind);
        
        
        if ~isempty(cu)
            if numel(cu) == 1            
                ypos = max(py);
                imslope = 0;
            elseif numel(cu)==2            
                imslope = (cv(2)-cv(1)) / (cu(2)-cu(1));
                ypos = cv(1) - imslope*cu(1);
            else
                rline = robustfit(cu, cv);
                ypos = rline(1);
                imslope = rline(2);            
            end
            by(k, :) = imslope*bx(k, :) + ypos;
            bz(k, :) = (1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST));        
            isvalid(k) = true;
        end
        
        contact{k} = [cu(:) cv(:)];
        
    end
end

bzmin(isvalid, :) = bz(isvalid, :);
bzmax(isvalid, :) = bz(isvalid, :);
unknown = (~isvalid) & (glabels==2);



%% Assign a maximum depth to object of unknown depth and sky
missing = unknown;

bzmax(missing, :) = Inf;

for k = find(missing)'
    bx(k, :) = bbox(k, [1 3]);
    by(k, :) = bbox(k, 4);
    
    tmpmax = 1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);
    
    if any(tmpmax < bzmax(k, :))
        bzmax(k, :) =tmpmax;
    end
end

% each region must be in back of things that occlude it (as far back as
% possible without being in front of things that it occludes)
missing2 = missing;
changed = 1;
while changed
    lastbz = bzmax;
    %bzmax(missing2, :) = Inf;
    for k = find(missing2)'
        bzmax(k, :) =  1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);
    end
    %changed = 0;
    for k = find(missing)'
        pos1 = find(ordering==k);
        
        for k2 = 1:numel(ordering)
            
            pos2 = find(ordering==k2);
            if pos1 < pos2  && glabels(k2)==2 && ~missing2(k2) ...
                    && (any(spLR(spLR(:, 1)==k, 2)==k2) || any(spLR(spLR(:, 2)==k, 1)==k2))
                % k is directly in front of k2
                imslope = (by(k2, 2)-by(k2, 1))./(bx(k2, 2)-bx(k2, 1));
                ypos = by(k2, 1) - imslope*bx(k2, 1);
                by(k, :) = imslope*bx(k, :) + ypos;
                tmpz = 1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);                
                
                if all(tmpz <= bzmax(k, :)) 
                    bzmax(k, :) = tmpz; %(1 ./ max(v0 - (imh-by(k, :))/imh, 0.01));
                    changed = 1;
                    missing2(k) = false;
                end
                        
            end
        end
    end
    if all(lastbz==bzmax)
        break;
    end
end

bzmax(isinf(bzmax(:, 1)), :) = 1./ MIN_HV_DIST;
    
%% Assign a minimum depth to objects of unknown depth;

missing = unknown;

% assign depth as maximum depth of object that occludes it
changed = 1;
while changed
    changed = 0;
    isvalid2 = isvalid;
    for k = find(missing)'
        bx(k, :) = bbox(k, [1 3]);
        
        bzmin(k, :) = 0; %bzmax(k, :);
        
        ind = find(spLR(:, 1)==k);
        neighbors = spLR(ind, 2);
        validn = isvalid(neighbors) & (glabels(neighbors)==2);
        neighbors = neighbors(validn);
        ind = ind(validn);
 
        pos1 = find(ordering==k);
        
        maxov = 0;
        for tk2 = 1:numel(neighbors)
            k2 = neighbors(tk2);  
            pos2 = find(ordering==k2);

            ov = min(bbox([k k2], 3)) - max(bbox([k k2], 1));          
            
            if ~missing(k2) && pos2 < pos1  && glabels(k2)==2 & ...
                    (any(spLR(spLR(:, 1)==k, 2)==k2) || any(spLR(spLR(:, 2)==k, 1)==k2)) 

                 %(ov > maxov) || (ov > 0.25*bbox(k, 3)-bbox(k,1))
                imslope = (by(k2, 2)-by(k2, 1))./(bx(k2, 2)-bx(k2, 1));
                ypos = by(k2, 1) - imslope*bx(k2, 1);
                by(k, :) = imslope*bx(k, :) + ypos;
                tmpz = 1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);                              
                
                if any(tmpz > bzmin(k, :)) 
                    bzmin(k, :) = tmpz; %(1 ./ max(v0 - (imh-by(k, :))/imh, 0.01));
                    missing(k) = false;
                    isvalid2(k) = true;
                    changed = 1;                    
                end

            end

        end
    end

    isvalid = isvalid2;        
    
end                   
bzmin(bzmin(:, 1)==0, :) = bzmax(bzmin(:, 1)==0, :);

% check that is not behind anything that it occludes
changed = 1;
while changed
    changed = 0;
    isvalid2 = isvalid;
    for k = find(missing)'
        bx(k, :) = bbox(k, [1 3]);        
        
        ind = find(spLR(:, 1)==k);
        neighbors = spLR(ind, 2);
        validn = isvalid(neighbors) & (glabels(neighbors)==2);
        neighbors = neighbors(validn);
        ind = ind(validn);
 
        pos1 = find(ordering==k);
        
        maxov = 0;
        for tk2 = 1:numel(neighbors)
            k2 = neighbors(tk2);
            pos2 = find(ordering==k2);             
            
            if ~missing(k2) && pos1 < pos2  &&  glabels(k2)==2 && ...
                    (any(spLR(spLR(:, 1)==k, 2)==k2) || any(spLR(spLR(:, 2)==k, 1)==k2)) 
                
                imslope = (by(k2, 2)-by(k2, 1))./(bx(k2, 2)-bx(k2, 1));
                ypos = by(k2, 1) - imslope*bx(k2, 1);
                by(k, :) = imslope*bx(k, :) + ypos;
                tmpz = 1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);                                                                        
                
                if all(tmpz < bzmin(k, :)) 
                    bzmin(k, :) = tmpz; 
                    missing(k) = false;
                    isvalid2(k) = true;
                    changed = 1;                    
                end

            end

        end
    end

    isvalid = isvalid2;        
    
end    


depthim = zeros([imh imw]);
tmpy = zeros(size(depthim));
tmpz = zeros(size(depthim));
for k = 1:bndinfo.nseg
    [y, x] = ind2sub(bndinfo.imsize, idx{k});    
    switch glabels(k)
        case 0
            z = bzmin(k, 1) + (x-bx(k, 1)) ./ ...
                (bx(k, 2)-bx(k, 1)) .* (bzmin(k,2)-bzmin(k,1));            
%             tmpy(idx{k}) = (y - (x-bx(k, 1)) ./ ...
%                 (bx(k, 2)-bx(k, 1)) .* (by(k,2)-by(k,1))) * 1.7 ./ ((x-bx(k, 1)) ./ ...
%                 (bx(k, 2)-bx(k, 1)) .* (bzmin(k,2)-bzmin(k,1)));
            tmpy(idx{k}) = -(v0 - (imh-(x-bx(k, 1)) ./ ...
                (bx(k, 2)-bx(k, 1)) .* (by(k,2)-by(k,1)))/imh).*z / 1.4 + 1.7;
            z2 = z;
        case 1
            z = 1 ./ max(v0 - (imh-y)/imh, MIN_HV_DIST);
            tmpy(idx{k}) = 0;
            z2 = z*1.4*1.7;
        case 2    
            z = bzmin(k, 1) + (x-bx(k, 1)) ./ ...
                (bx(k, 2)-bx(k, 1)) .* (bzmin(k,2)-bzmin(k,1));    
            ty = by(k,1) + (x-bx(k, 1)) ./ (bx(k, 2)-bx(k, 1)) .* (by(k,2)-by(k,1));
            
%             tmpy(idx{k}) = -(v0 - (imh-(x-bx(k, 1)) ./ ...
%                 (bx(k, 2)-bx(k, 1)) .* (by(k,2)-by(k,1)))/imh).*z / 1.4 + 1.7;         

            z2 = 1.4*1.7 ./ max(v0 - (imh-ty)/imh, MIN_HV_DIST);
            %(1.7-y(idx{k})) .* 1.4 ./ (v0 - (imh-ty)./imh+1E-5);            
        case 3
            z = SKY_DEPTH;            
            tmpy(idx{k}) = 500;            
            z2 = (1.7-tmpy(idx{k})) .* 1.4 ./ (v0 - (imh-y)./imh+1E-5);
    end    
    depthim(idx{k}) = log(z);
    tmpz(idx{k}) = z2;
end

imdepthMin = depthim;


% x = u.*z./f;


if DO_DISPLAY
    figure(1), imagesc(depthim), axis image, colormap jet
end
%print -f1 -djpeg99 ../tmp/gt_mindepth.jpg

%depthim = zeros([imh imw]);
for k = find(glabels==2)'
    [y, x] = ind2sub(bndinfo.imsize, idx{k});  
    zk = bzmax(k, 1) + (x-bx(k, 1)) ./ ...
        (bx(k, 2)-bx(k, 1)) .* (bzmax(k,2)-bzmax(k,1));    
    depthim(idx{k}) = log(zk);
end

if DO_DISPLAY
    figure(2), imagesc(depthim), axis image, colormap jet
end
%print -f2 -djpeg99 ../tmp/gt_maxdepth.jpg

imdepthMax = depthim;

x = repmat((1:imw)/imw-0.5, [imh 1]).*tmpz/1.4;
y = 1.7 - (v0-repmat(1-(1:imh)'./imh, [1 imw]))/1.4.*tmpz;
z = tmpz;


%% gets perimeter of region
function [py, px] = getPerimeter(bndinfo, r, npts)

imsize = bndinfo.imsize;
spLR = bndinfo.edges.spLR;
spLR = [spLR ; spLR(:, [2 1])];
eind = find(spLR(:, 1)==r);


failed = false;
order = zeros(1, numel(eind));
order(1) = 1;
for k = 2:numel(order)
    laste = eind(order(k-1));
    ismem = ismember(eind, bndinfo.edges.adjacency{laste});
    next = find(ismem);
    if numel(next)~=1
        failed = true;
        break;
    end
    order(k) = next;
end

if ~failed
    eind = eind(order);
end

edges = cell(numel(eind), 1);
for k = 1:numel(eind)
    if eind(k) <= bndinfo.ne
        edges{k} = bndinfo.edges.indices{eind(k)}(2:end-1);
    else
        edges{k} = bndinfo.edges.indices{eind(k)-bndinfo.ne}(end-1:-1:2);
    end
end
[py, px] = ind2sub(imsize, vertcat(edges{:}));

try
    ind = convhull(double(px), double(py));
catch
    ind = (1:5:numel(px))';
end

if npts > numel(ind) && ~failed
    step = ceil(numel(py) / (npts-numel(ind)));
    ind2 = (1:step:numel(py))';    
    ind = unique([ind ; ind2]);
end

py = double(py(ind));
px = double(px(ind));


