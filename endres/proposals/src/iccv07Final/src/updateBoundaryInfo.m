function [bndinfo2, err] = updateBoundaryInfo(bndinfo, result, im)

if isstruct(result) && isfield(result, 'regions')
    regions = result.regions;

    
    empty = false(numel(regions), 1);
    splab = zeros(bndinfo.nseg, 1);
    for k = 1:numel(regions)
        splab(regions{k}) = k;
        empty(k) = isempty(regions{k});        
    end
    regions(empty) = [];
else
    splab = result;
    regions = cell(max(splab), 1);
    empty = false(numel(regions), 1);
    for k = 1:numel(regions)
        regions{k} = find(splab==k);
        empty(k) = isempty(regions{k});  
    end
    regions(empty) = [];
end
    
wseg = splab(bndinfo.wseg);

% XXX only reading image until seg2fragments gets fixed
%im = imread(['/usr1/projects/dhoiem/iccv07/iccvGroundTruth/images/' bndinfo.imname]);
%im = im2double(im);

[edges, juncts, neighbors, wseg] = seg2fragments(wseg, im, 1);
bndinfo2 = processBoundaryInfo(wseg, edges, neighbors);

if isfield(bndinfo, 'imname')
    bndinfo2.imname = bndinfo.imname;
end

%bndinfo2.imname = bndinfo.imname;

stats = regionprops(bndinfo.wseg, 'Area');
area = cat(1, stats(:).Area);
bndinfo2.spArea = area;

if isfield(bndinfo, 'type')
    bndinfo2.type = bndinfo.type;
    bndinfo2.names = bndinfo.names;
    [bndinfo2.labels, err] = iccvTransferLabels(bndinfo.labels, regions, area);
    bndinfo2 = processGtBoundaryLabels(bndinfo2);

else
    err = nan;
end

bndinfo2 = orderfields(bndinfo2);