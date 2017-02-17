function boxes = masksToBoxes( segs, props )
    r = cell(length(segs));
    for i = 1:length(segs)
        r{i} = maskToBox( segs{i}, props{i} );
    end
    boxes = cat(1,r);
end