function [X, Y] = getFeatures(bndinfo, im, pbim, gconf, depthinfo)
% [X, Y] = getBoundaryFeatures(bndinfo, pbim, gconf)
% 
% Computes features for each edgelet based on boundary and geometry
% confidence images.  This version (3) computes geometry confidences as
% means of superpixel values on either side of the edglet.
%
% Input:
%   bndinfo - structure of superpixel boundaries
%   in(imh, imw, 3) - color image
%   pbim(imh, imw, norient) - probability of boundary image at each orientation
%   gconf(imh, imw, ngeoms) - confidence in each geometric label
%
% Output:
%   X(nboundaries, :) - features for the boundaries
%   Y(nboundaries, 2) - geometry on each size or 0 for no edge


%% Initialization

nsp = bndinfo.nseg;
edges = bndinfo.edges;
nbnd = bndinfo.ne*2; % number of directed edges
ne = bndinfo.ne;
[imh, imw] = size(bndinfo.wseg);

% set edge labels if ground truth is available
Y = zeros(nbnd, 1);
if isfield(bndinfo.edges, 'boundaryType')
    Y = bndinfo.edges.boundaryType;
end

X.edge.pb = zeros(ne, 1);
X.edge.theta = zeros(ne, 1);
X.edge.thetaStart = zeros(ne*2, 1);
X.edge.thetaEnd = zeros(ne*2, 1);
X.edge.smoothness = zeros(ne, 1);
X.edge.length = zeros(ne, 1);
X.edge.convArea = zeros(ne, 1);
X.edge.convRatio = zeros(ne, 1);
X.edge.depthmax = zeros(ne, 2); % mean depth (overestimate) on each side of edgelet
X.edge.depthmin = zeros(ne, 2); % mean depth (underestimate) on each side of edgelet
X.edge.chains = zeros(ne, 1); % chains;
X.edge.edge2chain = zeros(ne, 1);
X.edge.chainsize = zeros(ne, 1);

X.region.colorMean = zeros(nsp, 3); % Lab color mean
X.region.colorHist = [];  % set number of bins later (max 512)
%X.region.gradHist = []; % set number of bins later (max 64)
X.region.x = zeros(nsp, 3); % min, mean, max
X.region.y = zeros(nsp, 3); % min, mean, max
X.region.area = zeros(nsp, 1);
X.region.geomContext = zeros(nsp, 5);
X.region.pg1 = zeros(nsp, 7);
X.region.depthcol = zeros(nsp, 1);

%% Edge statistics

% get discretize orientation into 1=1|2, 2=1/2, 3=1_2, 4=2\1
theta = bndinfo.edges.thetaUndirected;
rels = (theta < -3*pi/8) + (theta < -pi/8) + (theta < pi/8) +  (theta < 3*pi/8); 
rels = mod(rels, 4) + 1;

X.edge.theta = bndinfo.edges.thetaDirected;  % directed edge angle

% pbim(imh, imw, [ -, \, |, / ]) (direction of edge)
pbmap = [3 4 1 2];

%X.edge.pbOrient = zeros(ne,4);
% compute features
for k = 1:ne 

    eind = edges.indices{k};
    
    X.edge.length(k) = numel(eind); % edge length
            
    pbsubi = pbmap(rels(k));    
    ind = double(eind + (pbsubi-1)*imh*imw);
    X.edge.pb(k) = sum(pbim(ind))/numel(ind);  % mean pb               
   
    % short-range angles
    y = mod(ind-1, imh)+1;
    x = floor((ind-1)/imh)+1;
    ni = numel(ind);
    de = 10; % length of edge used to measure angle
    x1 = x([1 min(de, ni)]);
    y1 = y([1 min(de, ni)]);
    x2 = x([max(ni-de+1, 1) ni]);
    y2 = y([max(ni-de+1, 1) ni]);
    X.edge.thetaStart(k) = atan2(-(y1(2)-y1(1)), x1(2)-x1(1));
    X.edge.thetaEnd(k) = atan2(-(y2(2)-y2(1)), x2(2)-x2(1));
    
    X.edge.smoothness(k) = (numel(ind)-1) / (abs(x(end)-x(1)) + abs(y(end)-y(1))+eps);    
    
    convarea = 0;
    %segcount = [0.5 0.5];
    if 0 && numel(x) > 2
        try
            [ch, convarea] = convhull(x, y);
%             mask = poly2mask(x(ch), y(ch), imh, imw);
%             segnums = bndinfo.wseg(mask);
%             segcount = [sum(segnums(:)==bndinfo.edges.spLR(k, 1)) ...
%                         sum(segnums(:)==bndinfo.edges.spLR(k, 2))];
        catch
        end
    end
    X.edge.convArea(k) = convarea / imh / imw;
    %X.edge.convRatio(k) = (segcount(1)+eps) / (sum(segcount)+2*eps);
    %X.edge.pbOrient(k, pbsubi) = X.edge.pb(k);
    
end

X.edge.thetaStart(ne+1:end) = X.edge.thetaEnd(1:ne)+pi;
X.edge.thetaEnd(ne+1:end) = X.edge.thetaStart(1:ne)+pi;

thetaEnd = mod(X.edge.thetaEnd*180/pi, 360);
thetaStart = mod(X.edge.thetaStart*180/pi, 360);
% chain together edgelets 
[chains, e2chain, chainsize] = chainEdgelets([X.edge.pb ; X.edge.pb], ...
    edges.adjacency, thetaStart, thetaEnd, 0.02, 45);
X.edge.chains = chains;
X.edge.edge2chain = single(e2chain);
X.edge.chainsize = single(chainsize);


%% Region statistics

% get area and position stats
stats = regionprops(bndinfo.wseg, 'PixelIdx', 'Area', 'Centroid', 'BoundingBox');

area = cat(1, stats(:).Area);
X.region.area = area / (imh*imw);

bbox = cat(1, stats(:).BoundingBox);
centroid = cat(1, stats(:).Centroid);
minx = bbox(:,1);
meanx = centroid(:, 1);
maxx = minx + bbox(:,3);
miny = bbox(:,2);
meany = centroid(:, 2);
maxy = miny + bbox(:,4);
X.region.x = [minx meanx maxx]/imw; % left, center, right
X.region.y = (1-[maxy meany miny]/imh); % bottom, center, top

% get lab color image
im = RGB2Lab(im);

% get discrete image with nb values per channel
nb = 8;
mincols = repmat(min(min(im)), [imh imw]);
maxcols = repmat(max(max(im))+1E-10, [imh imw]);
imd = floor((im-mincols)./(maxcols-mincols)*nb);
imd = imd(:, :, 1) + imd(:, :, 2)*nb + imd(:,:,3)*nb*nb + 1;

% get discrete texture image (does not help much)
% [gx, gy] = gradient(im(:, :, 1));
% gx = log(abs(gx)+1);
% gy = log(abs(gy)+1);
% gradim = [log(abs(gx(:))+1)  log(abs(gy(:))+1)];
% mingrad = repmat(min(gradim), [imh*imw 1]);
% maxgrad = repmat(max(gradim)+1E-10, [imh*imw 1]);
% gradim = floor((gradim-mingrad)./(maxgrad-mingrad)*nb);
% gradim = gradim(:, 1) + nb*gradim(:, 2) + 1;

% make gconf(:, :, [gnd planar porous solid sky])
gconf2 = gconf;
gconf = cat(3, gconf(:, :, 1), sum(gconf(:, :, 2:4), 3), gconf(:, :, 5:7));


% compute mean color
idx = {stats(:).PixelIdxList};
im = reshape(im, [imh*imw 3]);
for c = 1:3
    cim = im(:, c);
    for k = 1:nsp    
        X.region.colorMean(k,c) = sum(cim(idx{k})) / area(k);
    end
end

% compute mean geometric context
gconf = reshape(gconf, [imh*imw 5]);
for g = 1:5
    gim = gconf(:, g);
    for k = 1:nsp    
        X.region.geomContext(k,g) = sum(gim(idx{k})) / area(k);
    end
end
gconf2 = reshape(gconf2, [imh*imw 7]);
X.region.pg1(:, [1 5 6 7]) = X.region.geomContext(:, [1 3 4 5]);
for g = 2:4
    gim = gconf2(:, g);
    for k = 1:nsp
        X.region.pg1(k,g) = sum(gim(idx{k})) / area(k);
    end
end

% compute histograms of color and texture
imd =reshape(imd, [imh*imw 1]);
wseg = bndinfo.wseg;
colorHist = zeros(nsp, nb*nb*nb);
%gradHist = zeros(nsp, nb*nb);
for k = 1:imh*imw
    s = wseg(k);
    colorHist(s, imd(k)) = colorHist(s, imd(k)) + 1;
    %gradHist(s, gradim(k)) = gradHist(s, gradim(k)) + 1;
end

keep = sum(colorHist, 1)>0;  % only keep bins that have at least one value
colorHist = colorHist(:, keep);
X.region.colorHist = single(colorHist ./ repmat(area, [1 sum(keep)]));

% keep = sum(gradHist, 1)>0;  % only keep bins that have at least one value
% gradHist = gradHist(:, keep);
% X.region.gradHist = single(gradHist ./ repmat(area, [1 sum(keep)])); 


%% Depth range estimates
% get depth maps and min/max depth on each side of each edge
gc = X.region.geomContext;
gvs = cat(2, gc(:, 1), sum(gc(:, 2:4), 2), gc(:, 5));
[val, glab] = max(gvs, [], 2);
if ~exist('depthinfo', 'var') || isempty(depthinfo)
    try
      tmp = load('contactdt.mat');
      dt = tmp.contactdt;
    catch
      tmp = load('../iccv07/data4/contactTrainData.mat');
      dt = tmp.dt;
    end
    v0 = 0.5;
else
    dt = depthinfo.dt;
    v0 = depthinfo.v0;
end
    
[imdepthMin, imdepthMax, imdepthCol] = getDepthRange(bndinfo, glab, dt, v0);
edepthmin = zeros(ne, 2);
edepthmax = zeros(ne, 2);
for k = 1:ne
    try
    ind = bndinfo.edges.indices{k};
    if numel(ind)==2
        ey = bndinfo.junctions.position(bndinfo.edges.junctions(k, :), 2);
        ex = bndinfo.junctions.position(bndinfo.edges.junctions(k, :), 1);
    else
        [ey, ex] = ind2sub([imh imw], double(ind));
        ey = ey - 0.5;  ex = ex - 0.5;
    end
    if ey(1)==ey(2) && ex(1)==ex(2)
      
        ey([1 2]) = ey([2 3]);
        ex([1 2]) = ex([2 3]);
    end    
    if ey(2)==ey(1)-1 % going up
        edepthmin(k, 1) = imdepthMin(ey(1)-0.5, ex(1)-0.5); 
        edepthmin(k, 2) = imdepthMin(ey(1)-0.5, ex(1)+0.5);
        edepthmax(k, 1) = imdepthMax(ey(1)-0.5, ex(1)-0.5); 
        edepthmax(k, 2) = imdepthMax(ey(1)-0.5, ex(1)+0.5);        
    elseif ey(2)==ey(1)+1 % going down
        edepthmin(k, 1) = imdepthMin(ey(1)+0.5, ex(1)+0.5);
        edepthmin(k, 2) = imdepthMin(ey(1)+0.5, ex(1)-0.5);
        edepthmax(k, 1) = imdepthMax(ey(1)+0.5, ex(1)+0.5);
        edepthmax(k, 2) = imdepthMax(ey(1)+0.5, ex(1)-0.5);        
    elseif ex(2)==ex(1)-1 % going left
        edepthmin(k, 1) = imdepthMin(ey(1)+0.5, ex(1)-0.5);
        edepthmin(k, 2) = imdepthMin(ey(1)-0.5, ex(1)-0.5);
        edepthmax(k, 1) = imdepthMax(ey(1)+0.5, ex(1)-0.5);
        edepthmax(k, 2) = imdepthMax(ey(1)-0.5, ex(1)-0.5);        
    elseif ex(2)==ex(1)+1 % going right
        edepthmin(k, 1) = imdepthMin(ey(1)-0.5, ex(1)+0.5);
        edepthmin(k, 2) = imdepthMin(ey(1)+0.5, ex(1)+0.5);
        edepthmax(k, 1) = imdepthMax(ey(1)-0.5, ex(1)+0.5);
        edepthmax(k, 2) = imdepthMax(ey(1)+0.5, ex(1)+0.5);        
    end
    ey([1 2]) = ey([end-1 end]); % go to next junctions
    ex([1 2]) = ex([end-1 end]);
    if ey(1)==ey(2) && ex(1)==ex(2)
        ey([1 2]) = ey([end-2 end-1]);
        ex([1 2]) = ex([end-2 end-1]);
    end
    if ey(2)==ey(1)-1 % going up
        edepthmin(k, 1) = edepthmin(k, 1) + imdepthMin(ey(1)-0.5, ex(1)-0.5); 
        edepthmin(k, 2) = edepthmin(k, 2) + imdepthMin(ey(1)-0.5, ex(1)+0.5);
        edepthmax(k, 1) = edepthmax(k, 1) + imdepthMax(ey(1)-0.5, ex(1)-0.5); 
        edepthmax(k, 2) = edepthmax(k, 2) + imdepthMax(ey(1)-0.5, ex(1)+0.5);        
    elseif ey(2)==ey(1)+1 % going down
        edepthmin(k, 1) = edepthmin(k, 1) + imdepthMin(ey(1)+0.5, ex(1)+0.5);
        edepthmin(k, 2) = edepthmin(k, 2) + imdepthMin(ey(1)+0.5, ex(1)-0.5);
        edepthmax(k, 1) = edepthmax(k, 1) + imdepthMax(ey(1)+0.5, ex(1)+0.5);
        edepthmax(k, 2) = edepthmax(k, 2) + imdepthMax(ey(1)+0.5, ex(1)-0.5);        
    elseif ex(2)==ex(1)-1 % going left
        edepthmin(k, 1) = edepthmin(k, 1) + imdepthMin(ey(1)+0.5, ex(1)-0.5);
        edepthmin(k, 2) = edepthmin(k, 2) + imdepthMin(ey(1)-0.5, ex(1)-0.5);
        edepthmax(k, 1) = edepthmax(k, 1) + imdepthMax(ey(1)+0.5, ex(1)-0.5);
        edepthmax(k, 2) = edepthmax(k, 2) + imdepthMax(ey(1)-0.5, ex(1)-0.5);        
    elseif ex(2)==ex(1)+1 % going right
        edepthmin(k, 1) = edepthmin(k, 1) + imdepthMin(ey(1)-0.5, ex(1)+0.5);
        edepthmin(k, 2) = edepthmin(k, 2) + imdepthMin(ey(1)+0.5, ex(1)+0.5);
        edepthmax(k, 1) = edepthmax(k, 1) + imdepthMax(ey(1)-0.5, ex(1)+0.5);
        edepthmax(k, 2) = edepthmax(k, 2) + imdepthMax(ey(1)+0.5, ex(1)+0.5);        
    end  
    catch
    end
end
edepthmax = edepthmax / 2;
edepthmin = edepthmin / 2;
X.edge.depthmax = single(edepthmax);
X.edge.depthmin = single(edepthmin);
X.region.depthcol = single(imdepthCol);

X.region.depthmin = imdepthMin;
X.region.depthmax = imdepthMax;
% tmpim = zeros(bndinfo.imsize);
% for k = 1:ne
%     tmpim(bndinfo.edges.indices{k}) = abs(X.edge.depthmin(k, 1)-X.edge.depthmin(k, 2));
% end
% figure(3), hold off, imagesc(tmpim), axis image
% for k = 1:ne
%     tmpim(bndinfo.edges.indices{k}) = abs(X.edge.depthmax(k, 1)-X.edge.depthmax(k, 2));
% end
% figure(4), hold off, imagesc(tmpim), axis image
% keyboard;

