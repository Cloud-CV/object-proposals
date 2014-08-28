function [regions] = selectRegions(image_data)

BND_THRESH = 0.010;
AREA_THRESH = 20*20;


pb1 = image_data.occ.pb1;
pb2 = image_data.occ.pb2;
bndinfo = image_data.occ.bndinfo_all{1};

hier = boundaries2hierarchy(pb1+pb2, bndinfo.edges.spLR, 'mean');
cost = [hier.init_cost ; hier.cost];
stats = regionprops(bndinfo.wseg, 'Area');
area = cat(1, stats.Area);
keep = false(size(hier.regions));

for r = 1:numel(keep)
   keep(r) = ((sum(area(hier.regions{r}))>AREA_THRESH) && (cost(r)>BND_THRESH));
end
regions = hier.regions(keep);
