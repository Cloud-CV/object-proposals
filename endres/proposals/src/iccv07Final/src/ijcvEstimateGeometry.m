function [pg, data] = ijcvEstimateGeometry(im, imsegs, classifiers, smap, spdata, imdata)
% Computes the marginals of the geometry for the given input image
% spdata, adjlist, edata are optional inputs


vclassifier = classifiers.vclassifier;
hclassifier = classifiers.hclassifier;

if ~exist('spdata', 'var') || isempty(spdata)
    spdata = mcmcGetSuperpixelData(im, imsegs); 
end

if ~exist('imdata', 'var') || isempty(imdata)
    imdata = mcmcComputeImageData(im, imsegs);
end
   
labdata = mcmcGetSegmentFeatures(imsegs, spdata, imdata, smap(:), (1:max(smap)));
            
vconf = test_boosted_dt_mc(vclassifier, labdata);
vconf = 1 ./ (1+exp(-vconf));
vconf = vconf ./ repmat(sum(vconf, 2), [1 size(vconf, 2)]); 

hconf = test_boosted_dt_mc(hclassifier, labdata);
hconf = 1 ./ (1+exp(-hconf));
hconf = hconf ./ repmat(sum(hconf, 2), [1 size(hconf, 2)]);                    

pg = [vconf(:, 1) repmat(vconf(:, 2), [1 size(hconf, 2)]).*hconf vconf(:, 3)];
pg = pg ./ max(repmat(sum(pg, 2), 1, size(pg, 2)), 0.00001);    
   
data.spdata = spdata;
data.imdata = imdata;
data.imsegs = imsegs;

%% at later point may want to use faster sp classifier for small segments

% if nseg > 250  % use
%     % probability of superpixel main labels
%         vclassifierSP = classifiers.vclassifierSP;
%         hclassifierSP = classifiers.hclassifierSP;  
%     pvSP = test_boosted_dt_mc(vclassifierSP, spdata);
%     pvSP = 1 ./ (1+exp(-pvSP));
%     pvSP = pvSP ./ repmat(sum(pvSP, 2), 1, size(pvSP, 2));
%     [tmp, vmax] = max(pvSP, [], 2);
% 
%     % probability of superpixel sub labels
%     phSP = test_boosted_dt_mc(hclassifierSP, spdata);
%     phSP = 1 ./ (1+exp(-phSP));
%     phSP = phSP ./ repmat(sum(phSP, 2), 1, size(phSP, 2));
%     [tmp, hmax] = max(phSP, [], 2);