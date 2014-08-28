function gpts = APPcreateGroundPoints(lmap, gndmap)
% gpts = APPcreateGroundPoints(lmap, gndmap)
% Gets the ground-vertical boundary from the label map
% high y --> low in image, get max y for each x
%
% Copyright(C) Derek Hoiem, Carnegie Mellon University, 2005
% Permission granted to non-commercial enterprises for
% modification/redistribution under GNU GPL.  
% Current Version: 1.0  09/30/2005

height = size(lmap, 1);
width = size(lmap, 2);

count = 0;
[y, x] = find(lmap(1:end-1, :) & gndmap(2:end, :));
[y2, x2] = find(lmap(end, :));
gpts = ([(y(:)+1) x(:) ; y2(:)+(height-1) x2(:)]);
gpts(:, 1) = (gpts(:, 1)-1)/(height-1);
gpts(:, 2) = (gpts(:, 2)-1)/(width-1);
