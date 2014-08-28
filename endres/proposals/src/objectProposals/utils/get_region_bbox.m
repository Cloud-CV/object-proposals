function region_bb = get_region_bbox(regions, sp_bb)

for obj = 1:numel(regions)
   sub_bb = sp_bb(regions{obj},:);
   if(numel(sub_bb) > 0)
      region_bb(obj, :) = [min(sub_bb(:, 1)), min(sub_bb(:, 2)), max(sub_bb(:,3)), max(sub_bb(:, 4))];
   else
      region_bb(obj, :) = [-1 -1 -1 -1];
   end
end
