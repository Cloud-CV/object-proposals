function [regions, scores] = bndinfo2regions_scrap(bndinfo, imname, nr)
% [regions, scores] = bndinfo2regions_scrap(bndinfo, imname)
%  For playing around.

setOcclusionDirectories;

classifierfn = fullfile(traindir, ['boundaryClassifier_' alg]);

classifier = load(classifierfn, 'w');

iid = strtok(imname, '.');
occ = load(fullfile(occdir, [num2str(iid) '_occmap']));
%pb = load(fullfile(pbdir, [num2str(iid) '_pb']));
%pb2 = load(fullfile(pb2dir, [num2str(iid) '_pb2']));

ind = getBoundaryCenterIndices(bndinfo);
x = getBoundaryFeatures(ind, occ); %, pb, pb2);

pB = getBoundaryLikelihood(x, classifier.w);

%pB = (1-bndinfo.pbnd(1:bndinfo.ne));

niter = 1;
maxov = 0.75;
[regions, scores] = sampleRegions(pB, bndinfo.edges.spLR, bndinfo.wseg, niter, maxov, nr);
numel(regions)

im = imread(fullfile(imdir, imname));
figure(1), imagesc(im), axis image
bmap = getPbImage(pB, bndinfo);
figure(2), imagesc(bmap), axis image, colormap gray

[segs,uids] = readSegs('color', str2num(iid));
s = regionprops(bndinfo.wseg, 'Area');
area = cat(1, s.Area);  area = area/sum(area);
rmap = zeros(bndinfo.nseg, 1);
totalov = zeros(1, numel(segs));
for k = 1:numel(segs)
    lab = transferRegionLabels(segs{k}, bndinfo.wseg);
    for r1 = 1:max(lab)
        region1 = find(lab==r1);        
        maxov = 0;
        maxr = 0;        
        for r2 = 1:numel(regions)
            ov = regionOverlap(region1, regions{r2}, area);
            if ov > maxov
                maxr = r2;
                maxov = ov;
            end
        end
        totalov(k) = totalov(k) + sum(area(region1))*maxov;       
%         disp(num2str(maxov))
%         if maxov>0
%             rmap(:) = 0; rmap(region1) = 1;
%             figure(3), imagesc(im.*repmat(uint8(rmap(bndinfo.wseg)), [1 1 3])); axis image; 
%             rmap(:) = 0; rmap(regions{maxr}) = 1;
%             figure(4), imagesc(im.*repmat(uint8(rmap(bndinfo.wseg)), [1 1 3])); axis image;         
%             pause;
%         end
    end
end
disp([num2str(mean(totalov)) ': ' num2str(totalov)]);
% rmap = zeros(bndinfo.nseg, 1);
% for r = 1:numel(regions); 
%     disp([num2str(r) ': ' num2str(scores(r))]); 
%     rmap(:) =0; 
%     rmap(regions{r}) = 1; 
%     figure(3), imagesc(im.*repmat(uint8(rmap(bndinfo.wseg)), [1 1 3])); axis image; 
%     pause; 
% end
