function [segs, ind] = checksegs(segs, map, s)
% Checks whether this segment has been seen before

ind = find(map==s);
if isempty(ind)
    return;
end
oldsegs = segs{ind(1)};
for k = 1:numel(oldsegs)
    if (numel(oldsegs{k})==numel(ind)) && all(oldsegs{k}==ind)
        ind = [];
        return;
    end
end
segs{ind(1)}{end+1} = ind;