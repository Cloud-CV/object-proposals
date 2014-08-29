function areaIntersection = computeIntersectionArea(bb1,bb2)
%compute intersection anrea of bb1 and bb2
%bb1 and bb2 - bounding boxes
%bbi = [xmin ymin xmax ymax] for i=1,2

xmin = max(bb1(1),bb2(1));
xmax = min(bb1(3),bb2(3));
ymin = max(bb1(2),bb2(2));
ymax = min(bb1(4),bb2(4));

areaIntersection = computeArea([xmin ymin xmax ymax]);

end