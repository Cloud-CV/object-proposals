function combs = floodfill_sp_all(sp, mask)
% Get all floodfills on superpixel graph 'sp'. Remove all sp specified by
% 'mask' from consideration.

nesp = []; % "non-empty superpixels"
for i = 1:length(sp)
    if sp{i}.size > 0
        nesp = [nesp, i];
        sp{i}.neighbors = setdiff_fast(sp{i}.neighbors, mask); % filter neighbors
    end
end
nesp = setdiff(nesp, mask);

combs = [];
zr = 1;
while ~isempty(nesp)
    combs{zr} = floodfill_sp(sp, nesp(1)); % do individual floodfills
    nesp(1) = [];
    nesp = setdiff(nesp, combs{zr});
    zr = zr + 1;
end

% Adds all combinations of disjoint floodfills, provided there's up to 4 of
% them (includes the set of all allowed sp)
% disjoint_regions = length(combs);
% if disjoint_regions >= 2 && disjoint_regions <= 4
%     for l = 2:disjoint_regions
%         c = combnk(1:disjoint_regions, l);
%         for j = 1:size(c,1)
%             combs{end+1} = horzcat(combs{c(j,:)});
%         end
%     end
% end
