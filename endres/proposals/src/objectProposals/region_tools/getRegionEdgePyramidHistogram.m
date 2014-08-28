function [rhist, bbox] = getRegionEdgePyramidHistogram(segmap, pbmap, thresh, omap, norient, grid)

nr = max(segmap(:));
ncells = sum(prod(grid, 2));
rhist = zeros(nr, ncells*(norient+1));

% get rid of border edges
pbmap(:, [1 end]) = 0;
pbmap([1 end], :) = 0;

stats = regionprops(segmap, 'BoundingBox');
bbox = cat(1, stats.BoundingBox); % [x1 y1 w h]

[imh, imw] = size(pbmap);
[y, x] = find(pbmap>thresh);
idx = y+(x-1)*imh;

orient = omap(idx);
pb = pbmap(idx);

% get indices for 4-neighborhood for each edge pixel
ind1 = idx;
ind2 = idx+1;
ind3 = idx-1;
ind4 = idx+imh;
ind5 = idx-imh;

emap = segmap([ind1 ind2 ind3 ind4 ind5]);
for r = 1:nr
        
    indr = any(emap==r, 2);
    rx = x(indr);
    ry = y(indr);
    ro = orient(indr);
    rpb = pb(indr);
    
    rx = min(max((rx-bbox(r, 1))/bbox(r,3),0),1);
    ry = min(max((ry-bbox(r, 2))/bbox(r,4),0),1);
    
    f = 0;
    for L = 1:size(grid, 1) % level
        for i = 1:grid(L, 1) % cell x
            w = grid(L,1);
            for j = 1:grid(L, 2); % cell y
                h = grid(L, 2);
                ind = (rx >= (i-1)/w) & (rx<= i/w) & (ry >= (j-1)/h) & (ry<=j/h);
                tmpro = ro(ind);
                tmprpb = rpb(ind);
                for o = 1:norient
                    rhist(r, f+o) = sum((tmpro==o).*tmprpb);
                end
                sume = sum(rhist(r, f+(1:norient)));
                rhist(r, f+(1:norient)) = rhist(r, f+(1:norient))/(sume+1);                
                rhist(r, f+norient+1) = sume / (bbox(r,3)*bbox(r,4)/w/h);
                f = f + norient+1;
            end
        end
    end
end
              
bbox = [bbox(:, 1:2) bbox(:, 1:2)+bbox(:, 3:4)-1]; % [x1 y1 x2 y2]