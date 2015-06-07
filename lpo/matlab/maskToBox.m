function boxes = maskToBox( seg, prop )
    boxes = lpo_mex('maskToBox', seg, prop );
end