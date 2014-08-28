function [py, px] = getPerimeter(bndinfo, r, npts)
% [py, px] = getPerimeter(bndinfo, r, npts)
% 
% gets perimeter of region

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
