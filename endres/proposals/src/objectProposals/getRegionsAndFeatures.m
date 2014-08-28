function [regions, Xshape, Xapp, Xbbox] = getRegionsAndFeatures(image_data)

[regions] = selectRegions(image_data);

Pobject = 1-image_data.bg;
Pobject = Pobject / max(Pobject(:));
Psolid = image_data.gconf(:, :, 5);
Psolid = Psolid/max(Psolid(:));


[Xshape Xapp] = getSubregionFeatures(image_data, regions, Pobject, Psolid);

norient = 8; hsize = [4 4];
npertype = norient*prod(hsize);
hog = regions2hog(regions, image_data.occ.bndinfo_all{1}, image_data.occ.pb1, image_data.occ.pb2, norient, hsize);
Xbbox = [hog(1:4*npertype, :) ; hog(5*npertype+1:end, :)]';

