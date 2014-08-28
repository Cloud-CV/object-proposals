function overlaps = get_regions_overlaps(regions, bndinfo, lb)

sp_areas_struct = regionprops(bndinfo.wseg, 'Area');
sp_areas = [sp_areas_struct.Area];


areas = zeros(1,length(regions));
region_inds = zeros(numel(sp_areas), numel(regions));
region_areas = zeros(numel(sp_areas), numel(regions));

for i = 1:length(regions) %
   areas(i) = sum(sp_areas(regions{i}));
   region_inds(regions{i}, i) = 1;
   region_areas(regions{i}, i) = sp_areas(regions{i});
end

rinds = 1:length(regions);
tic;
for i = 1:length(regions)
   if(toc>1)
       fprintf('%d/%d\n', i, length(regions));
       tic;
   end
    
   ov_estimate = min(areas(i),areas) >= (lb*max(areas(i),areas));
   to_consider = find(ov_estimate & rinds > i);

   ind_cell{i} = zeros(length(to_consider), 2);
   v{i} = zeros(length(to_consider), 1);

   for j = 1:length(to_consider)
      r = to_consider(j);
      
%      v{i}(j) = regionOverlap(regions{i}, regions{r}, sp_areas);
      ind_cell{i}(j,:) = [i r];
   end
    %keyboard
   v{i} = get_region_overlap_mex(regions{i}, regions(to_consider), sp_areas)';
   %v{i} = get_region_overlap(region_inds(:, i), region_inds(:, to_consider), region_areas(:,i), region_areas(:, to_consider))';
   
end

inds = cat(1,ind_cell{:});
vs = cat(1, v{:});

bigger = vs>=lb;
inds = inds(bigger,:);
vs = vs(bigger);

overlaps = sparse([inds(:,1);inds(:,2)], [inds(:,2); inds(:, 1)], [vs;vs], numel(regions),numel(regions));
