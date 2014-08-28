function [regions new_score new2old] = region_nms(regions, scores, th, sp_areas, bndinfo)

scores_orig = scores;
regions_orig = regions;

[scores reg_ind] = sort(scores,'descend');
regions = regions(reg_ind);

%[dk new2old] = sort(reg_ind);

areas = zeros(1,length(regions));
for i = 1:length(regions) %
   areas(i) = sum(sp_areas(regions{i}));
end


%to_consider = cell(size(regions));
%tic;
%for i = 1:length(regions)
%   if(toc>1)
%       fprintf('%d/%d\n', i, length(regions));
%       tic;
%%   end
%end


remove = zeros(size(regions));
tic;
for i = 1:length(regions)
   if(toc>1)
       fprintf('%d/%d\n', i, length(regions));
       tic;
   end
    
   if(remove(i))
      continue
   end

   ov_estimate = min(areas(i),areas) >= (th*max(areas(i),areas));
   to_consider = find(ov_estimate & ([1:length(regions)] > i));

   for j = 1:length(to_consider)
      r = to_consider(j);
%      int = sum(sp_areas(intersect(regions{i}, regions{r})));
%      un = sum(sp_areas(union(regions{i}, regions{r})));
      
      if(regionOverlap(regions{i}, regions{r}, sp_areas) >= th)
         %display_regions(bndinfo, cat(2,regions([i,r])), 'count');
         %pause
         
         remove(r) = 1;
%         break
      end
   end
end

regions = regions(~remove);
new_score = scores(~remove);
%new2old = new2old(~remove);
new2old = reg_ind(~remove);
return
