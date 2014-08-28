function [imdepthMin, imdepthMax, imdepthCol] = getDepthRange(bndinfo, glabels, dt, v0)
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
                 
            try 
                [cu, cv] = poly2contacts(dt, px, py, bndinfo.imsize, v0, 1.7, [], 0.5);
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
    end
end

bzmin(isvalid, :) = bz(isvalid, :);
bzmax(isvalid, :) = bz(isvalid, :);
unknown = (~isvalid) & (glabels==2);



%% Assign a maximum depth to object of unknown depth and sky
missing = unknown;
for k = find(missing)'
    bx(k, :) = bbox(k, [1 3]);
    by(k, :) = bbox(k, 4);
    bzmax(k, :) = 1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);   
end
    
    
%% Assign a minimum depth to objects of unknown depth;

missing = unknown;

changed = 1;
while changed
    changed = 0;
    isvalid2 = isvalid;
    for k = find(missing)'
        bx(k, :) = bbox(k, [1 3]);
        
        bzmin(k, :) = bzmax(k, :);
        
        ind = find(spLR(:, 1)==k);
        neighbors = spLR(ind, 2);
        validn = isvalid(neighbors) & (bbox(neighbors, 4) > bbox(k, 4));
        neighbors = neighbors(validn);
        ind = ind(validn);
       
        
        maxov = 0;
        for tk2 = 1:numel(neighbors)
            k2 = neighbors(tk2);

            ov = min(bbox([k k2], 3)) - max(bbox([k k2], 1));
            %ov = numel(bndinfo.edges.indices{mod(ind(tk2)-1,bndinfo.ne)+1});

            if (ov > maxov) || (ov > 0.25*bbox(k, 3)-bbox(k,1))
                imslope = (by(k2, 2)-by(k2, 1))./(bx(k2, 2)-bx(k2, 1));
                ypos = by(k2, 1) - imslope*bx(k2, 1);
                by(k, :) = imslope*bx(k, :) + ypos;
                tmpz = 1 ./ max(v0 - (imh-by(k, :))/imh, MIN_HV_DIST);
                if all(tmpz < bzmin(k, :))
                    bzmin(k, :) = tmpz; %(1 ./ max(v0 - (imh-by(k, :))/imh, 0.01));
                end
                maxov = ov;
                missing(k) = false;
                isvalid2(k) = true;
                changed = 1;
            end

        end
    end

    isvalid = isvalid2;        
    
end                   



depthim = zeros([imh imw]);
for k = 1:bndinfo.nseg
    [y, x] = ind2sub(bndinfo.imsize, idx{k});
    switch glabels(k)
        case 0
            z = bzmin(k, 1) + (x-bx(k, 1)) ./ ...
                (bx(k, 2)-bx(k, 1)) .* (bzmin(k,2)-bzmin(k,1));            
        case 1
            z = 1 ./ max(v0 - (imh-y)/imh, MIN_HV_DIST);
        case 2    
            z = bzmin(k, 1) + (x-bx(k, 1)) ./ ...
                (bx(k, 2)-bx(k, 1)) .* (bzmin(k,2)-bzmin(k,1));    
        case 3
            z = SKY_DEPTH;            
    end
    depthim(idx{k}) = log(z);
end

imdepthMin = depthim;

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





