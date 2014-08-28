function ov = regionOverlap(r1, r2, area1, area2)
% compute intersection over union of two regions
% ov = regionOverlap(region1, region2, area)

%area = area(:);

a_int = slmetric_pw(area1, r2, 'dotprod');

a_plus_b = slmetric_pw(-area1, area2, 'cityblk');

if(numel(r2)==0)
    ov = [];
else
    ov = a_int./(a_plus_b - a_int);
end

