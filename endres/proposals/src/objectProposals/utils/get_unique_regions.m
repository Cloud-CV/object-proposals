function [regions first_occ corresp]= get_unique_regions(regions_in, n_sps);

if(~exist('n_sps', 'var'))
   n_sps = max(cat(1,regions_in{:}));
end

sp_map = zeros(numel(regions_in), n_sps);

for prop = 1:length(regions_in)
   sp_map(prop,regions_in{prop}) = 1;
end

[unique_regions first_occ corresp] = unique(sp_map, 'first', 'rows');

regions = {};

for i = 1:size(unique_regions,1)
   regions{i} = find(unique_regions(i,:));
end
