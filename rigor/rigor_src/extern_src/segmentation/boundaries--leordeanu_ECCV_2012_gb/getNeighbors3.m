function  [cur_locs, dist, f] = getNeighbors3(locs2, yx, idx, rad)

%disp(' getNeighbors.m ');

yxl = round(yx-rad);

if yxl(1) <= 0
  yxl(1) = 1;
end

if yxl(2) <= 0
  yxl(2) = 1;
end

yxu = round(yx+rad);

if yxu(1) > size(idx,1)
     yxu(1) = size(idx,1);
end

if yxu(2) > size(idx,2)
     yxu(2) = size(idx,2);
end

idxs = idx(yxl(1):yxu(1),yxl(2):yxu(2));

ff = find(idxs);

candidates = idxs(ff);

candidates = candidates(:);

rad = rad^2;

yx = repmat(yx,length(ff),1);

locs2(candidates,:);

dist = sum(((yx - locs2(candidates,:)).^2)');

ff = find(dist < rad);

f = candidates(ff);

cur_locs = locs2(f,:);
dist = sqrt(dist(ff));