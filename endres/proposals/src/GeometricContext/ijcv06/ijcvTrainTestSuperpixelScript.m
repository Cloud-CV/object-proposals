% ijcvTrainTestSuperpixelScript

imdir = '/IUS/vmr7/dhoiem/context/images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';

ncv = 5;

load(['/IUS/vmr7/dhoiem/context/data/rand_indices.mat']);

% simpler features
if ~exist('spfeatures1')
    disp('getting superpixel features 1')    
    tmp = load(['/IUS/vmr7/dhoiem/context/data/mcmcSuperpixelData.mat']);
    spfeatures1 = tmp.spfeatures;
    splabels = {imsegs(:).labels};
    spw = {imsegs(:).npixels}';
    for f = 1:numel(spw)
        spw{f} = spw{f} / sum(spw{f});
    end
    clear tmp;
end

% complete feature set
if ~exist('spfeatures2')
    disp('getting superpixel features 2') 
    for f = 1:numel(imsegs)
        maps{f} = [1:imsegs(f).nseg]';
    end
    spfeatures2 = mcmcGetAllSegmentFeatures(imsegs, imdir, maps, spfeatures1);    
end

if ~exist('spvclassifier1')
    disp('training superpixel classifiers 1 and 2')
    for k = 1:ncv
        disp(['iteration ' num2str(k)])
        testind = cv_images((k-1)*50+1:k*50);
        trainind = setdiff([1:numel(imsegs)], testind);
        [spvclassifier1(k), sphclassifier1(k)] = ...
            mcmcTrainSegmentClassifier2(spfeatures1(trainind), splabels(trainind), spw(trainind), 50000);    
        [spvclassifier2(k), sphclassifier2(k)] = ...
            mcmcTrainSegmentClassifier2(spfeatures2(trainind), splabels(trainind), spw(trainind), 50000);             
    end
    save([outdir '/spTrain.mat'], 'spfeatures1', 'spfeatures2', 'splabels', ...
        'spvclassifier1', 'sphclassifier1', 'spvclassifier2', 'sphclassifier2', 'spw');
end

disp('testing superpixel classifiers')
[spvacc1, sphacc1, spvcm1, sphcm1, pg1] = ...
    testSingleSegmentationsCV(imsegs(cv_images), spfeatures1(cv_images), maps(cv_images), spvclassifier1, sphclassifier1, ncv);
disp(num2str([spvacc1 sphacc1]))
[spvacc2, sphacc2, spvcm2, sphcm2, pg2] = ...
    testSingleSegmentationsCV(imsegs(cv_images), spfeatures2(cv_images), maps(cv_images), spvclassifier2, sphclassifier2, ncv);
%[spvacc1, sphacc1, sptacc1, spvcm1, sphcm1] = mcmcTestSegmentClassifierCV(...
%    spvclassifier1, sphclassifier1, imsegs, spfeatures1, splabels, cv_images, spw);
%[spvacc2, sphacc2, sptacc2, spvcm2, sphcm2] = mcmcTestSegmentClassifierCV(...
%    spvclassifier2, sphclassifier2, imsegs, spfeatures2, splabels, cv_images, spw);

save([outdir '/spResults.mat'], 'spvacc1', 'sphacc1', 'spvcm1', 'sphcm1', ...
    'spvacc2', 'sphacc2', 'spvcm2', 'sphcm2', 'pg1', 'pg2');
