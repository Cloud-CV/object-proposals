function [x1,y1,x2,y2] = retrieveCoordinates(index,scale)
% compute coordinates [x1,y1,x2,y2] from an index which represent the a
% window in the scale^4 space of all the windows

image_area = scale*scale;
index1 = mod(index, image_area);
index2 = floor(index/image_area);

x1 = mod(index1, scale) + 1;
y1 = floor(index1/scale) + 1;

x2 = mod(index2, scale) + 1;
y2 = floor(index2/scale) + 1;

return

