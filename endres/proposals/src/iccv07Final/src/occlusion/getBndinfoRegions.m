function regions = getBndinfoRegions(bndinfo)
% regions = getBndinfoRegions(bndinfo)
% bndinfo should be a cell array (e.g., bndinfo_all)

regions = cell(numel(bndinfo), 1);
regions{1} = num2cell((1:bndinfo{1}.nseg)');
for k = 2:numel(bndinfo)
    [rmap, tmp, err] = transferRegionLabels(double(bndinfo{k}.wseg), double(bndinfo{1}.wseg));
    %disp(num2str(err));
    regions{k} = cell(bndinfo{k}.nseg, 1);
    for k2 = 1:bndinfo{k}.nseg
        regions{k}{k2} = find(rmap==k2)';
    end
end
regions = cat(1, regions{:});
        