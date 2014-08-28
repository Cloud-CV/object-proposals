% ijcvTrainTestPixelScript

imdir = '/IUS/vmr7/dhoiem/context/images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';

ncv = 5;

load(['/IUS/vmr7/dhoiem/context/data/rand_indices.mat']);

if ~exist('pixfeatures')
    disp('getting pixel features')
    [pixfeatures, pixlabels] = ijcvPixelFeatures(imdir, imsegs, 1000);
end

if ~exist('pixvclassifier')
    disp('training pixel classifiers')
    for k = 1:ncv
        disp(['iteration ' num2str(k)])
        testind = cv_images((k-1)*50+1:k*50);
        trainind = setdiff([1:numel(imsegs)], testind);
        [pixvclassifier(k), pixhclassifier(k)] = ...
                mcmcTrainSegmentClassifier2(pixfeatures(trainind), pixlabels(trainind), [], 50000);    
    end
    save([outdir '/pixTrain.mat'], 'pixfeatures', 'pixlabels', 'pixvclassifier', 'pixhclassifier');
end

disp('testing pixel classifiers')
[pixvacc, pixhacc, pixtacc, pixvcm, pixhcm] = mcmcTestSegmentClassifierCV(...
    pixvclassifier, pixhclassifier, imsegs, pixfeatures, pixlabels, cv_images, []);

save([outdir '/pixResults.mat'], 'pixvacc', 'pixhacc', 'pixtacc', 'pixvcm', 'pixhcm');
