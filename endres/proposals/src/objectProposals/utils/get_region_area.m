function area = get_region_area(bndinfo_all, regions)

stats = regionprops(bndinfo_all{1}.wseg, 'Area');
a = [stats.Area];
for r = 1:numel(regions)
   area(r) = sum(a(regions{r}));
end
