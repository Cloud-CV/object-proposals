function hog = regions2mog(regions, bndinfo, pb1, pb2, norient, hogSize)
% hog = regions2mog(regions, bndinfo, pb1, pb2, norient, hogSize)
% maximum of gradient pyramid

%% get basic edge statistics
edges = bndinfo.edges;
theta = edges.thetaDirected; % range from 0 to pi, left side occludes
ind_c = getBoundaryCenterIndices(bndinfo);
[ey, ex] = ind2sub(bndinfo.imsize, ind_c);

ew = zeros(bndinfo.ne, 1);
for k = 1:bndinfo.ne
    ew(k) = numel(bndinfo.edges.indices{k})-2;
end
ew1 = pb1.*(ew>0);
ew2 = pb2.*(ew>0);
ew12 = ew1+ew2;

stats =regionprops(bndinfo.wseg, 'BoundingBox');
bbox = cat(1, stats.BoundingBox); %x1 y1 w h
bbox(:, 1:2) = bbox(:, 1:2)+0.5;
bbox(:, 3:4) = bbox(:, 1:2) + bbox(:, 3:4);  %x1 y1 x2 y2

hog = zeros(sum(prod(hogSize, 2))*(norient)*5+3, numel(regions));

nregions = numel(regions);
for k = 1:nregions
    left = false(bndinfo.ne, 1);
    right = false(bndinfo.ne, 1);
    for k2 = 1:numel(regions{k})
        left(edges.spLR(:, 1)==regions{k}(k2)) = true;
        right(edges.spLR(:, 2)==regions{k}(k2)) = true;
    end
    
    x1 = min(bbox(regions{k},1)); x2 = max(bbox(regions{k},3));
    relx = (ex-x1+1)/(x2-x1+1);
    y1 = min(bbox(regions{k},2)); y2 = max(bbox(regions{k},4));
    rely = (ey-y1+1)/(y2-y1+1);
    
    bb = [x1 y1 x2 y2];
    
    % exterior boundaries by which region occludes
    ind1 = left&~right; ind2 = right&~left; 
    theta_tmp = [theta(ind1) ; theta(ind2)+pi];  ew_tmp = [ew1(ind1) ; ew2(ind2)];
    relx_tmp = [relx(ind1) ; relx(ind2)]; rely_tmp = [rely(ind1) ; rely(ind2)];    
    hog_occludes = getHOG2(relx_tmp, rely_tmp, ew_tmp, theta_tmp, norient*2, hogSize, [ew(ind1) ; ew(ind2)]);    
    %[hog_occludes, nf] = normalizeHOG(hog_occludes, norient*2, hogSize);        
    nfactor1 = sum([ew1(left & ~right) ; ew2(right & ~left)]) ./ (1+sum(ew((left & ~right) | (right &~left))));
    %nfactor1 = nf / (1+sum(ew((left&~right) | (right&~left))));
        
    % exterior boundaries by which region is occluded
    theta_tmp = [theta(ind1) ; theta(ind2)+pi];  ew_tmp = [ew2(ind1) ; ew1(ind2)];    
    hog_occluded = getHOG2(relx_tmp, rely_tmp, ew_tmp, theta_tmp, norient*2, hogSize, [ew(ind1) ; ew(ind2)]);        
    %[hog_occluded, nf] = normalizeHOG(hog_occluded, norient*2, hogSize);    
    nfactor2 = sum([ew2(left & ~right) ; ew1(right & ~left)]) ./ (1+sum(ew((left & ~right) | (right &~left))));
    %nfactor2 = nf / (1+sum(ew((left&~right) | (right&~left))));        
    
    % interior boundaries
    hog_interior = getHOG(relx, rely, ew12, theta, left&right, norient, hogSize, ew(left&right));
    %[hog_interior, nf] = normalizeHOG(hog_interior, norient, hogSize);
    nfactor3 = sum(ew12(left & right)) ./ (1+sum(ew(left&right)));
    %nfactor3 = nf / (1+sum(ew((left&right))));        
    
    hog(:, k) = [hog_occludes ; hog_occluded ; hog_interior ; nfactor1 ; nfactor2; nfactor3];
    
end

% gets hog for specified edgelets
function hog = getHOG(relx, rely, ew, theta, activeInd, norient, hogSize, ew_norm)
theta  = (theta + pi/2)/pi;
theta_bin = round(theta(activeInd)*(norient*2+1));
theta_bin(theta_bin==norient*2+1) = 1;
theta_bin = ceil(theta_bin/2);
theta_bin(theta_bin==0) = 1;

relx = relx(activeInd);
rely = rely(activeInd);
ew = ew(activeInd);

nhog = sum(prod(hogSize, 2), 1);
hog = zeros(nhog*norient,1);
c = 0;
for k = 1:size(hogSize, 1)
    x = ceil(relx*hogSize(k,2));
    y = ceil(rely*hogSize(k,1));
    ind = y + hogSize(k,1)*(x-1);
    indo = theta_bin + norient*(ind-1);   
    
    nb = prod(hogSize(k, :))*norient;
    for b = 1:nb                       
        if any(indo==b)
            hog(c+b) = max(ew(indo==b)); % / (sum(ew_norm(ind==ceil(b/norient)))+0.01);
        end
        
    end
    c = c+nb;    
       
end
   

% gets hog for specified edgelets
function hog = getHOG2(relx, rely, ew, theta, norient, hogSize, ew_norm)
theta  = (theta + pi/2)/pi/2;
theta_bin = round(theta*(norient*2+1));
theta_bin(theta_bin==(norient*2+1)) = 1;
theta_bin = ceil(theta_bin/2);
theta_bin(theta_bin==0) = 1;

nhog = sum(prod(hogSize, 2), 1);
hog = zeros(nhog*norient,1);
c = 0;
for k = 1:size(hogSize, 1)
    x = ceil(relx*hogSize(k,2));
    y = ceil(rely*hogSize(k,1));
    ind = y + hogSize(k,1)*(x-1);
    indo = theta_bin + norient*(ind-1);   
    
    nb = prod(hogSize(k, :))*norient;
    for b = 1:nb
        if any(indo==b)
            hog(c+b) = max(ew(indo==b)); % / (sum(ew_norm(ind==ceil(b/norient)))+0.01);
        end
    end
    c = c+nb;    
       
end

%% Normalization 
function [hog, nfactor] = normalizeHOG(hog, norient, hogSize)

nhog = sum(prod(hogSize, 2), 1);
nfactor = zeros(nhog, 1);
for k = 1:nhog
    ind = ((k-1)*norient+1):(k*norient);
    totalsq = sum(hog(ind).^2);    
    hog(ind) = hog(ind) ./ sqrt(totalsq+1);    
    nfactor(k) = sqrt(totalsq);
    %nfactor(k) = sqrt(totalsq)/sqrt((bb(3)-bb(1)+1).^2 + (bb(4)-bb(2)+1).^2);
end        




