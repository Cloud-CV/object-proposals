function [region_data] = processData2RegionFeatures(image_data, classifier_bbox, classifier)

bndinfo_all = image_data.occ.bndinfo_all;

fprintf('\tExtracting per segment features...');
start_seg = tic;
[region_data.regions, ...
 region_data.Xshape, ...
 region_data.Xapp, ...
 region_data.Xbbox] = getRegionsAndFeatures(image_data);
fprintf('Done (%f)\n', toc(start_seg));


fprintf('\tPredicting bounding box and object labels...');
start_pred = tic;
pred = zeros(size(region_data.Xshape,1), 6);
for s = 1:4
    pred(:, s) = lrLikelihood(region_data.Xbbox, classifier_bbox(s).w);
end
pred(:,5) = test_boosted_dt_mc(classifier.pure, region_data.Xshape);
pred(:,6) = test_boosted_dt_mc(classifier.object, region_data.Xshape);

region_data.predictions = pred;
fprintf('Done (%f)\n', toc(start_pred));

fprintf('\tExtracting segment pair features...');
start_pair = tic;
[region_data.pair_feats] = segmentPairFeatInitial(image_data, region_data);
fprintf('Done (%f)\n', toc(start_pair));
