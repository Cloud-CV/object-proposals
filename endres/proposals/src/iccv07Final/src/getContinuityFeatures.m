function [tx, cf] = getContinuityFeatures(X, bndinfo, c1, nextc, pB, bndx)

% XXX add features for chain and short-range continuity

nextc = reshape(nextc, [1 numel(nextc)]);
nc2 = numel(nextc);

tx = zeros(nc2, 126); % features: continuity + pContour of same type
  
ne = bndinfo.ne;

% get relative angles between c1 and contours in c2
theta = bndinfo.edges.thetaDirected(mod([c1 nextc]-1, ne)+1) / pi * 180;
theta([c1 nextc]>ne) = theta([c1 nextc]>ne) + 180;
theta(theta > 180) = (theta(theta>180)-360);
relAngle = theta(2:end)-theta(1);
relAngle(relAngle > 180) = relAngle(relAngle > 180)-360;
relAngle(relAngle <= -180) = relAngle(relAngle <= -180)+360;
   
relAngle2 = mod((X.edge.thetaEnd(c1) - X.edge.thetaEnd(nextc))*180/pi, 360);

for tc = 1:nc2
    
    c2 = nextc(tc);    
           
    tx(tc, 1:5) = [relAngle(tc)       abs(relAngle(tc)) ...
                    relAngle2(tc)      abs(relAngle2(tc)) ...
                    X.edge.length(c2 - ne*(c2>ne))];   
    if c2 <= ne
        tx(tc, 6:65) = bndx(c2, 1:60);
    else % mirror and negate features where necessary
        tc2 = c2 - ne;
        tx(tc, 6:65) = [bndx(tc2, 1:14) -bndx(tc2, 15:18) bndx(tc2, [20 19]) ...
            -bndx(tc2, 21:22) bndx(tc2, [24 23 25:28 34:38 29:33]) ...
            -bndx(tc2, 39:43) bndx(tc2, [44:45 47 46 49 48]) -bndx(tc2, 50:51) ...
            bndx(tc2, [52 54 53]) -bndx(tc2, 55) bndx(tc2, 56:60)];
    end
    if c1 <= ne
        tx(tc, 66:125) = bndx(c1, 1:60);
    else  % mirror and negate features where necessary
        tc1 = c1 - ne;
        tx(tc, 66:125) = [bndx(tc1, 1:14) -bndx(tc1, 15:18) bndx(tc1, [20 19]) ...
            -bndx(tc1, 21:22) bndx(tc1, [24 23 25:28 34:38 29:33]) ...
            -bndx(tc1, 39:43) bndx(tc1, [44:45 47 46 49 48]) -bndx(tc1, 50:51) ...
            bndx(tc1, [52 54 53]) -bndx(tc1, 55) bndx(tc1, 56:60)];        
    end
        
    chain1 = X.edge.edge2chain(c1);
    chain2 = X.edge.edge2chain(c2);
    if (chain1==chain2) && (chain1 > 0)
        tx(tc, 126) = X.edge.chainsize(chain1);
    end                    
                    
end

cf = [];

