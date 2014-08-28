function ov = regionOverlap(region1, region2, area)
% compute intersection over union of two regions
% ov = regionOverlap(region1, region2, area)

area = area(:);
r1 = false(numel(area), 1);
r2 = false(numel(area), 1);
r1(region1) = true;
r2(region2) = true;
ov = sum(area(r1 & r2)) / sum(area(r1 | r2));
