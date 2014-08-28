% ijcvTestOrientationScript

outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
imdir = '../images/all_images';

if 0
    load '../data/rand_indices.mat';
    load '../data/allimsegs2.mat';    
    tmp = load([outdir '/spTrain.mat']);
    spvclassifier = tmp.spvclassifier1;
    sphclassifier = tmp.sphclassifier1;
    spfeatures_000 = tmp.spfeatures1;
    
    tmp = load([outdir '/spResults.mat']);
    [pv_000, ph_000] = splitpg(tmp.pg1);    
end

for f = 1:numel(imsegs)
    maps{f} = [1:imsegs(f).nseg]';
end

ncv = 5;

if 0
if ~exist('spfeatures_090')
    disp('getting superpixel features 090')
    tmpsegs = imsegs(cv_images);
    for f = 1:numel(tmpsegs)
        tmpsegs(f).segimage = imrotate(tmpsegs(f).segimage, 90);
    end
        
    spfeatures_090 = mcmcGetAllSuperpixelData(imdir, tmpsegs);         
    [tmp1, tmp2, tmp3, tmp4, pg_090] = ...
        testSingleSegmentationsCV(tmpsegs, spfeatures_090, maps(cv_images), spvclassifier, sphclassifier, ncv);
    [pv_090, ph_090] = splitpg(pg_090);
end
end

if 0 
if ~exist('spfeatures_180')
    disp('getting superpixel features 180')
    tmpsegs = imsegs(cv_images);
    for f = 1:numel(tmpsegs)
        tmpsegs(f).segimage = imrotate(tmpsegs(f).segimage, 180);
    end        
    spfeatures_180 = mcmcGetAllSuperpixelData(imdir, tmpsegs);         
    [tmp1, tmp2, tmp3, tmp4, pg_180] = ...
        testSingleSegmentationsCV(tmpsegs, spfeatures_180, maps(cv_images), spvclassifier, sphclassifier, ncv);
    [pv_180, ph_180] = splitpg(pg_180);
end

if ~exist('spfeatures_270')
    disp('getting superpixel features 270')
    tmpsegs = imsegs(cv_images);
    for f = 1:numel(tmpsegs)
        tmpsegs(f).segimage = imrotate(tmpsegs(f).segimage, 270);
    end        
    spfeatures_270 = mcmcGetAllSuperpixelData(imdir, tmpsegs);         
    [tmp1, tmp2, tmp3, tmp4, pg_270] = ...
        testSingleSegmentationsCV(tmpsegs, spfeatures_270, maps(cv_images), spvclassifier, sphclassifier, ncv);
    [pv_270, ph_270] = splitpg(pg_270);
end

end

conf = [];
for f = 1:numel(cv_images)
    cvf = cv_images(f);
    conf(f, 1) = sum(imsegs(cvf).npixels(:).*max(pv_000{f}, [], 2))/sum(imsegs(cvf).npixels(:));
    conf(f, 2) = sum(imsegs(cvf).npixels(:).*max(pv_090{f}, [], 2))/sum(imsegs(cvf).npixels(:));
    conf(f, 3) = sum(imsegs(cvf).npixels(:).*max(pv_180{f}, [], 2))/sum(imsegs(cvf).npixels(:));    
    conf(f, 4) = sum(imsegs(cvf).npixels(:).*max(pv_270{f}, [], 2))/sum(imsegs(cvf).npixels(:)); 
end

[val, ind] = max(conf, [], 2);
acc = mean(ind==1);

save([outdir '/orientationResults.mat'], 'conf', 'pv_000', 'pv_090', 'pv_180', 'pv_270', 'acc');
