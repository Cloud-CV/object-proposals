function [imdepthMin, imdepthMax, imdepthCol, contact, x, y, z] = makeDepthImages(bndinfo)

global DO_DISPLAY;
DO_DISPLAY = 0;

load '/home/dhoiem/src/cmu/iccv07Final/data/contactdt.mat';


[tmp, glabels] = max(bndinfo.result.geomProb, [], 2); 
glabels((glabels>=2) & (glabels<=4)) = 2;
glabels(glabels==5) = 3;

lab = bndinfo.edges.boundaryType;

lab = lab(1:end/2) + 2*lab(end/2+1:end);

[imdepthMin, imdepthMax, imdepthCol, contact, x, y, z] = ...
    getDepthRangeForDisplay(bndinfo, glabels, lab, contactdt, 0.5);