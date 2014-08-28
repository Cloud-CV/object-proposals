function tx = updateFastBoundaryClassifierFeatures(X, s1, s2, eid)
% tx = updateFastBoundaryClassifierFeatures(X, s1, s2, eid)
%
% Computes a simple set of features based on two regions s1 and s2, each
% containing one or more segments from X and separated by edglets given by
% eid.


ng = 5; % five geometric classes

tx = zeros([1 33], 'single');

f = 0;


%% Edge features
tx(f+1) = sum(X.edge.pb(eid).*X.edge.length(eid)) / sum(X.edge.length(eid));
    
area1 = X.region.area(s1);
area2 = X.region.area(s2);

f = f+1;

%% Region features

% area
sumarea1 = sum(area1);
sumarea2 = sum(area2);
tx(f+(1:2)) = [min([sumarea1 sumarea2], [], 2) max([sumarea1 sumarea2], [], 2)];

% color
meanColor1 = sum(X.region.colorMean(s1, :).*[area1 area1 area1], 1) / sumarea1;
meanColor2 = sum(X.region.colorMean(s2, :).*[area2 area2 area2], 1) / sumarea2;
tx(f+3) = sqrt(sum((meanColor1-meanColor2).^2, 2));

% position
left1 = min(X.region.x(s1, 1));  right1 = max(X.region.x(s1, 3));
left2 = min(X.region.x(s2, 1));  right2 = max(X.region.x(s2, 3));
bot1 = min(X.region.y(s1, 1));  top1 = max(X.region.y(s1, 3));
bot2 = min(X.region.y(s2, 1));  top2 = max(X.region.y(s2, 3));

tx(f+4) = top1-top2;
tx(f+5) = bot1-bot2;
tx(f+6) = top1-bot2; 
tx(f+7) = bot1-top2;
tx(f+8) = top1-bot1;
tx(f+9) = top2-bot2;
tx(f+10) = left1-left2;
tx(f+11) = right1-right2;
tx(f+12) = right1-left1;
tx(f+13) = right2-left2; 

% x alignment
x1 = [left1 right1]; 
x2 = [left2 right2]; 
tx(f+14) = (min([x1(:, 2) x2(:, 2)], [], 2)-max([x1(:, 1) x2(:, 1)], [], 2)) ./ ...
    (max([x1(:, 2) x2(:, 2)], [], 2)-min([x1(:, 1) x2(:, 1)], [], 2));

% y overlap
y1 = [bot1 top1]; 
y2 = [bot2 top2]; 
tx(f+15) = (min([y1(:, 2) y2(:, 2)], [], 2)-max([y1(:, 1) y2(:, 1)], [], 2)) ./ ...
    (max([y1(:, 2) y2(:, 2)], [], 2)-min([y1(:, 1) y2(:, 1)], [], 2));

f = f + 15;


%% 3D Geometry features

% geometric context features
gc = X.region.geomContext;
gc1 = sum(gc(s1, :).*repmat(area1, [1 size(gc, 2)]), 1) / sumarea1;
gc2 = sum(gc(s2, :).*repmat(area2, [1 size(gc, 2)]), 1) / sumarea2;

tx(f+(1:ng)) = gc1;
tx(f+ng+(1:ng)) = gc2;
tx(f+2*ng+(1:ng)) = gc1-gc2; 
tx(f+3*ng+1) = sum(abs(gc1-gc2), 2)/2;

[maxval1, maxlab1] = max([gc1(:, 1) sum(gc1(:, 2:4), 2) gc1(:, 5)], [], 2);
[maxval2, maxlab2] = max([gc2(:, 1) sum(gc2(:, 2:4), 2) gc2(:, 5)], [], 2);
tx(f+3*ng+2) = (maxlab1-1)*3+ maxlab2;

f= f + 17;

