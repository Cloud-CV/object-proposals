function segms = segmentArea(N)

%coords
tot_segms = max(max(N));
for sid = 1:tot_segms
   [r c] = find(N==sid);
   segms(sid).coords = uint16([c'; r']);
end

%area
for sid = 1:tot_segms
    segms(sid).area = length(segms(sid).coords);    
end

end