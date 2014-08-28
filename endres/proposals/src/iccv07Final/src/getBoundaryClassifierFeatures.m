function [tx, categoryFeatures] = getBoundaryClassifierFeatures(bndinfo, X, ind)
% X is the raw data
% ind is the set of indices for which the features should be computed
%
% tx:
%   Edge features (1-6)
%        1:  Pb
%        2:  Length / Perimeter
%        3:  Smoothness
%        4:  Angle
%      5-6:  Continuity
%      7-8:  Convexity (area and ratio) - not used
%        9:  Chain length
%   Region features (7-17)+3
%    10-11:  Area
%       12:  Color Mean Difference
%       13:  Color Entropy Difference
%       14:  Gradient Entropy Difference - not used
%    15-16:  Position (x,y)
%    17-18:  Extent Overlap (x, y)
%    an additional 10 features of position/overlap
%   Geometry features (16-39)+3
%    19-28:  Geometric Context Mean
%    29-33:  Geometric Context Difference
%    34   :  Geometric Context Sum Abs Difference
%    35-36:  Geometric Context Most Likely Label (G V or S)
%    37-40:  Depth under- and over-estimates for each side
%    31-43:  Depth, min1-min2, max1-max2, min(max12) - max(min12)
%    44-47:  Depthcol, each sp, diff, abs diff




ng = 5; % five geometric classes

ndata = numel(ind);

[imh, imw] = size(bndinfo.wseg);

tx = zeros([ndata 60], 'single');

if isempty(ind)
    return;
end

spLR = bndinfo.edges.spLR;
s1 = spLR(ind, 1);
s2 = spLR(ind, 2);
wseg = bndinfo.wseg;

categoryFeatures = [];
f = 0;


%% Edge features
tx(:, f+1) = X.edge.pb(ind);

perim = zeros(bndinfo.nseg, 1);
for k = 1:numel(X.edge.length)
    perim(spLR(k, 1)) = perim(spLR(k, 1)) + X.edge.length(k);
    perim(spLR(k, 2)) = perim(spLR(k, 2)) + X.edge.length(k);
end
minperim = min([perim(s1) perim(s2)], [], 2);
tx(:, f+2) = X.edge.length(ind) ./ minperim; % edge length / perim of smaller region

% juncts = bndinfo.edges.junctions(ind, :);
% jpos1 = bndinfo.junctions.position(juncts(:, 1), :);
% jpos2 = bndinfo.junctions.position(juncts(:, 2), :);
% directLength = abs(jpos2(:, 1)-jpos1(:,1)) + abs(jpos2(:, 2)-jpos1(:,2));
tx(:, f+3) = X.edge.smoothness(ind); % measure of smoothess
    
theta = X.edge.theta;
% discrete angle
tx(:, f+4) = max(ceil((mod(theta(ind),2*pi) / (pi*2) * 16 - 1E-10)),1); 
categoryFeatures(end+1) = f+4;

% relative angle (continuity)
%theta = mod([theta ; theta+pi]/pi*180, 360);
theta1 = mod(X.edge.thetaStart*180/pi, 360);
theta2 = mod(X.edge.thetaEnd*180/pi, 360);
maxc = zeros(ndata, 2);
eadj = bndinfo.edges.adjacency;
ne = bndinfo.ne;
for k = 1:ndata
    ki = ind(k);
    ra = abs(theta2(ki)-theta1(eadj{ki}));
    ra = ra - 180*(ra>180);
    if isempty(ra), maxc(k,1) = 0;
    else maxc(k,1) = min(ra);
    end    
    ra = mod(abs(theta2(ne+ki)-theta1(eadj{ne+ki})), 180+1E-5);         
    if isempty(ra), maxc(k,2) = 0;
    else maxc(k,2) = min(ra);
    end    
end
tx(:, f+(5:6)) = [min(maxc, [], 2) max(maxc, [], 2)];

area1 = X.region.area(s1);
area2 = X.region.area(s2);
%tx(:, f+7) = X.edge.convArea(ind) ./ min([area1 area2], [], 2);
%tx(:, f+8) = 0; %X.edge.convRatio;


%ind2 = (X.edge.edge2chain(ind)>0);
%tx(ind2, f+9) = X.edge.chainsize(X.edge.edge2chain(ind(ind2)));
tx(:, f+9) = X.edge.edge2chain(ind);

f = f + 9;


%% Region features

% area

tx(:, f+(1:2)) = [min([area1 area2], [], 2) max([area1 area2], [], 2)];

% color
tx(:, f+3) = sqrt(sum((X.region.colorMean(s1, :)-X.region.colorMean(s2, :)).^2, 2));

ch = X.region.colorHist+1E-10;
for k = 1:ndata
    h1 = ch(s1(k), :);  e1 = sum(-log(h1).*h1);
    h2 = ch(s2(k), :);  e2 = sum(-log(h2).*h2);
    e12 = (area1(k)*e1 + area2(k)*e2)/(area1(k)+area2(k));
    h3 = (area1(k)*h1 + area2(k)*h2)/(area1(k)+area2(k));
    e3 = sum(-log(h3).*h3);
    tx(k, f+4) = e3-e12;
end

% gradient
% ch = X.region.gradHist+1E-10;
% for k = 1:ndata
%     h1 = ch(s1(k), :);  e1 = sum(-log(h1).*h1);
%     h2 = ch(s2(k), :);  e2 = sum(-log(h2).*h2);
%     e12 = (area1(k)*e1 + area2(k)*e2)/(area1(k)+area2(k));
%     h3 = (area1(k)*h1 + area2(k)*h2)/(area1(k)+area2(k));
%     e3 = sum(-log(h3).*h3);
%     tx(k, f+5) = e3-e12;
% end

% position
tx(:, f+6) = (X.region.y(s1, 3))-(X.region.y(s2, 3)); % difference of tops
tx(:, f+7) = (X.region.y(s1, 1))-(X.region.y(s2, 1)); % difference of bottoms
tx(:, f+8) = (X.region.y(s1, 3))-(X.region.y(s2, 1)); % top1 - bottom2
tx(:, f+9) = (X.region.y(s1, 1))-(X.region.y(s2, 3)); % bottom1 - top2
tx(:, f+10) = X.region.y(s1, 3) - X.region.y(s1, 1); % top1 - bottom1
tx(:, f+11) = X.region.y(s2, 3) - X.region.y(s2, 1); % top2 - bottom2
tx(:, f+12) = (X.region.x(s1, 1))-(X.region.x(s2, 1)); % left1 - left2
tx(:, f+13) = (X.region.x(s1, 3))-(X.region.x(s2, 3)); % right1 - right2
tx(:, f+14) = X.region.x(s1, 3) - X.region.x(s1, 1); % right1 - left1
tx(:, f+15) = X.region.x(s2, 3) - X.region.x(s2, 1); % right2 - left2

%tx(:, f+6) = (X.region.x(s1, 2)-X.region.x(s2, 2)) / imw;
%tx(:, f+7) = (X.region.y(s1, 2)-X.region.y(s2, 2)) / imh;    

% x alignment
x1 = X.region.x(s1, [1 3]);
x2 = X.region.x(s2, [1 3]);
tx(:, f+16) = (min([x1(:, 2) x2(:, 2)], [], 2)-max([x1(:, 1) x2(:, 1)], [], 2)) ./ ...
    (max([x1(:, 2) x2(:, 2)], [], 2)-min([x1(:, 1) x2(:, 1)], [], 2));

% determine whether regions are x-aligned at boundary
jpos1 = ceil(bndinfo.junctions.position(bndinfo.edges.junctions(ind, 1), :));
jpos2 = ceil(bndinfo.junctions.position(bndinfo.edges.junctions(ind, 2), :));
if jpos1(:, 1)>jpos2(:, 1) % make jpos1 the left-most junction
    tmp = jpos2;
    jpos2 = jpos1;
    jpos1 = tmp;
end
tx(:, f+17) = (jpos2(:, 1)-jpos1(:, 1))/imw; % boundary width
jpos1(:, 1) = max(jpos1(:, 1)-3, 1);  % go a little to left of left junction
jpos2(:, 1) = min(jpos2(:, 1)+3, imw); % go a little to right or right junction
jpos1(:, 2) = min(jpos1(:, 2), imh);
jpos2(:, 2) = min(jpos2(:, 2), imh);
js1 = wseg((jpos1(:, 1)-1)*imh + jpos1(:, 2)); % region slightly to left
js2 = wseg((jpos2(:, 1)-1)*imh + jpos2(:, 2)); % region slightly to right
tx(:, f+18) = (js1~=s1) & (js1~=s2) & (js2~=s1) & (js2~=s2); % whether x-aligned

% y overlap
y1 = X.region.y(s1, [1 3]);
y2 = X.region.y(s2, [1 3]);
tx(:, f+19) = (min([y1(:, 2) y2(:, 2)], [], 2)-max([y1(:, 1) y2(:, 1)], [], 2)) ./ ...
    (max([y1(:, 2) y2(:, 2)], [], 2)-min([y1(:, 1) y2(:, 1)], [], 2));

f = f + 19;


%% 3D Geometry features

% geometric context features
gc = X.region.geomContext;

tx(:, f+(1:ng)) = gc(s1, :);
tx(:, f+ng+(1:ng)) = gc(s2, :);
tx(:, f+2*ng+(1:ng)) = tx(:, f+(1:ng))-tx(:, f+ng+(1:ng));
tx(:, f+3*ng+1) = sum(abs(tx(:, f+2*ng+(1:ng))), 2)/2;

[maxval, maxlab] = max([gc(:, 1) sum(gc(:, 2:4), 2) gc(:, 5)], [], 2);
tx(:, f+3*ng+2) = (maxlab(s1)-1)*3+ maxlab(s2);
categoryFeatures(end+1) = f+3*ng+2;

f = f + 17;

% relative depth
tx(:, f+(1:4)) = [X.edge.depthmin(ind, 1:2)  X.edge.depthmax(ind, 1:2)];
tx(:, f+5) = X.edge.depthmin(ind, 1)-X.edge.depthmin(ind,2);
tx(:, f+6) = X.edge.depthmax(ind, 1)-X.edge.depthmax(ind,2);
tx(:, f+7) = min(X.edge.depthmax(ind, :), [], 2)- max(X.edge.depthmin(ind, :), [], 2);

tx(:, f+(8:9)) = X.region.depthcol([s1 s2]);
tx(:, f+10) = tx(:, f+8)-tx(:, f+9);
tx(:, f+11) = abs(tx(:, f+10));


%% Geometric T-junctions
% Ground-Vertical-Ground junctions
% In future make this faster by checking chains to see when g/v transitions
% to v/v
gvs1 = zeros(bndinfo.ne, 1);  gvs2 = zeros(bndinfo.ne, 1);
gvs1(ind) = maxlab(s1);
gvs2(ind) = maxlab(s2);
is_gv = (gvs1==1 & gvs2==2) | (gvs1==2 & gvs2==1);
is_vv = (gvs1==2 & gvs2==2);
ejuncts = bndinfo.edges.junctions;
juncts = cell(bndinfo.nj, 1);
jsize = zeros(size(juncts));
for k = 1:size(ejuncts, 1)
    j1 = ejuncts(k, 1);  j2 = ejuncts(k, 2); 
    juncts{j1}(end+1) = k;
    juncts{j2}(end+1) = k;
    jsize(j1) = jsize(j1) + 1;
    jsize(j2) = jsize(j2) + 1;
end
juncts = cell2mat(juncts(jsize==3));
isGeomJunction = sum(is_gv(juncts), 2)==2 & sum(is_vv(juncts), 2)==1;
juncts = juncts(isGeomJunction, :);
nGeomJuncts = zeros(bndinfo.nseg, 1);
e2chain = X.edge.edge2chain;
spLR = [bndinfo.edges.spLR ; bndinfo.edges.spLR(:, [2 1])];
for k = 1:size(juncts, 1) % check that g/v --> v/v angle is less than g/v -->         
    gve = juncts(k, is_gv(juncts(k, :)));   
    % if ground on left, then reverse
    vve = juncts(k, is_vv(juncts(k, :)));
    if maxlab(spLR(gve(1), 1))==1, gve(1) = gve(1)+ne;  end
    if maxlab(spLR(gve(2), 1))==1, gve(2) = gve(2)+ne;  end
    if any(e2chain(vve)==e2chain(gve)) && (e2chain(vve)>0) % foreground on left
        chainind = sort(X.edge.chains{e2chain(vve)});
        chainind1 = chainind(chainind<=ne);
        chainind2 = chainind(chainind>ne)-ne;
        tmpind = ismember_sorted(ind, chainind1);
        tx(tmpind, f+12) = 1;
        tmpind = ismember_sorted(ind, chainind2);
        tx(tmpind, f+12) = 2;                
        nGeomJuncts(spLR(vve, 1)) = nGeomJuncts(spLR(vve, 1))+1;        
    elseif any(e2chain(vve+ne)==e2chain(gve)) && (e2chain(vve+ne)>0) % foreground on right
        chainind = sort(X.edge.chains{e2chain(vve+ne)});
        chainind1 = chainind(chainind<=ne);
        chainind2 = chainind(chainind>ne)-ne;              
        tmpind = ismember_sorted(ind, chainind1);
        tx(tmpind, f+12) = 1;
        tmpind = ismember_sorted(ind, chainind2);
        tx(tmpind, f+12) = 2; 
        nGeomJuncts(spLR(vve, 2)) = nGeomJuncts(spLR(vve, 2))+1;        
    end
end
categoryFeatures(end+1) = f+12;

% add feature if segment has two or more geometric T-junctions
tmpind = find(tx(:, f+12)>0);
for k = tmpind'
    if tx(k, f+12)==1 && nGeomJuncts(spLR(ind(k), 1))>1
        tx(k, f+13) = 1;
    elseif tx(k, f+12)==2 && nGeomJuncts(spLR(ind(k), 2))>1
        tx(k, f+13) = 2;
    end
end
categoryFeatures(end+1) = f+13;    


% Sky-Vertical-Vertical junctions (same as above but substitute sky for
% ground) 
% In future make this faster by checking chains to see when s/v transitions
% to v/v
is_gv = (gvs1==3 & gvs2==2) | (gvs1==2 & gvs2==3);
is_vv = (gvs1==2 & gvs2==2);
ejuncts = bndinfo.edges.junctions;
juncts = cell(bndinfo.nj, 1);
jsize = zeros(size(juncts));
for k = 1:size(ejuncts, 1)
    j1 = ejuncts(k, 1);  j2 = ejuncts(k, 2); 
    juncts{j1}(end+1) = k;
    juncts{j2}(end+1) = k;
    jsize(j1) = jsize(j1) + 1;
    jsize(j2) = jsize(j2) + 1;
end
juncts = cell2mat(juncts(jsize==3));
isGeomJunction = sum(is_gv(juncts), 2)==2 & sum(is_vv(juncts), 2)==1;
juncts = juncts(isGeomJunction, :);
nGeomJuncts = zeros(bndinfo.nseg, 1);
e2chain = X.edge.edge2chain;
for k = 1:size(juncts, 1) % check that g/v --> v/v angle is less than g/v -->         
    gve = juncts(k, is_gv(juncts(k, :)));   
    % if ground on left, then reverse
    vve = juncts(k, is_vv(juncts(k, :)));
    if maxlab(spLR(gve(1), 1))==3, gve(1) = gve(1)+ne;  end
    if maxlab(spLR(gve(2), 1))==3, gve(2) = gve(2)+ne;  end
    if any(e2chain(vve)==e2chain(gve)) && (e2chain(vve)>0) % foreground on left
        chainind = sort(X.edge.chains{e2chain(vve)});
        chainind1 = chainind(chainind<=ne);
        chainind2 = chainind(chainind>ne)-ne;
        tmpind = ismember_sorted(ind, chainind1);
        tx(tmpind, f+14) = 1;
        tmpind = ismember_sorted(ind, chainind2);
        tx(tmpind, f+14) = 2;                
        nGeomJuncts(spLR(vve, 1)) = nGeomJuncts(spLR(vve, 1))+1;        
    elseif any(e2chain(vve+ne)==e2chain(gve)) && (e2chain(vve+ne)>0) % foreground on right
        chainind = sort(X.edge.chains{e2chain(vve+ne)});
        chainind1 = chainind(chainind<=ne);
        chainind2 = chainind(chainind>ne)-ne;              
        tmpind = ismember_sorted(ind, chainind1);
        tx(tmpind, f+14) = 1;
        tmpind = ismember_sorted(ind, chainind2);
        tx(tmpind, f+14) = 2; 
        nGeomJuncts(spLR(vve, 2)) = nGeomJuncts(spLR(vve, 2))+1;        
    end
end
categoryFeatures(end+1) = f+14;

% add feature if segment has two or more geometric T-junctions
tmpind = find(tx(:, f+14)>0);
for k = tmpind'
    if tx(k, f+14)==1 && nGeomJuncts(spLR(ind(k), 1))>1
        tx(k, f+15) = 1;
    elseif tx(k, f+14)==2 && nGeomJuncts(spLR(ind(k), 2))>1
        tx(k, f+15) = 2;
    end
end
categoryFeatures(end+1) = f+15;


%% Object features
if isfield(X, 'objectFeatures')
    tx = [tx X.objectFeatures(ind, :)];
end