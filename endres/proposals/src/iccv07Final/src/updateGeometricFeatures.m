function [X, gdata] = updateGeometricFeatures(im, X, segmaps, gclassifiers, ...
    gdata, gparams)
% 
%  [X, gdata] = updateGeometricFeatures(im, X, segmaps, gclassifiers,gdata, gparams)
%
 
gclassifiers.vclassifier = gclassifiers.vclassifier(1);
gclassifiers.hclassifier = gclassifiers.hclassifier(1);
    
if isempty(segmaps)
    segmaps = (1:gdata.imsegs.nseg); 
end

if isfield(gdata, 'spdata')
    [pg, gdata] = ijcvEstimateGeometry([], gdata.imsegs, gclassifiers, ...
        segmaps, gdata.spdata, gdata.imdata);
else
    [pg, gdata] = ijcvEstimateGeometry(im, gdata.imsegs, gclassifiers, ...
        segmaps, [], []);    
end

pg2 = pg;
X.region.pg2 = pg;

pg1 = X.region.pg1;
pg1 = [pg1(:, 1) sum(pg1(:, 2:4), 2) pg1(:, 5:7)];
pg2 = [pg2(:, 1) sum(pg2(:, 2:4), 2) pg2(:, 5:7)];        
pg = exp(gparams(1)*log(pg1) + gparams(2)*log(pg2));
pg = pg ./ repmat(sum(pg, 2), [1 size(pg, 2)]);

X.region.geomContext = pg;