%function [pg, energy, map, allenergy] = mcmcEvaluate(imsegs, imdir, vclassifierSP, hclassifierSP, ...
%    eclassifier, ecal, vclassifier, hclassifier, sclassifier, spdata, adjlist, edata)

DO_LOAD = 1;

if DO_LOAD
    clear
    load '../data/allimsegs2.mat';
    load '../data/rand_indices.mat';
    load '../data/mcmcEdgeData.mat';
    load '../data/mcmcEdgeClassifier.mat';
    load '../data/mcmcSuperpixelData.mat';
    load '../data/mcmcSuperpixelClassifier.mat';    
    load '/IUS/vmr20/dhoiem/data/ijcv06/priors.mat';
    tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/spSegResults2.mat');    
    %tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/multisegResults2.mat');
    vclassifier = tmp.vclassifier;
    hclassifier = tmp.hclassifier;
    load('/IUS/vmr20/dhoiem/data/mcmcdata/segmentationRegressionTree2.mat');
    clear tmp;
end

imdir = '/IUS/vmr7/dhoiem/context/images/all_images';

ncv = numel(vclassifier);

maxIter = 50;

for tf = 1:numel(cv_images)
    
    f = cv_images(tf);
    
    c = ceil(f/numel(imsegs)*ncv);
    
    disp([num2str(tf) ': ' imsegs(f).imname])
    
    im = im2double(imread([imdir '/' imsegs(f).imname]));
            
    [pg{tf}, smaps{tf}, segs2{tf}, segpg2{tf}, pg2{tf}, e1(tf), e2(tf)] = mcmcTestImageSA3(im, imsegs(f), ...
        vclassifierSP, hclassifierSP, eclassifier, ecal{c}, vclassifier(c), hclassifier(c), ...
        segrt(c), priors(c, :), maxIter, spfeatures{f}, adjlist{f}, efeatures{f});
    [vacc1, hacc1] = mcmcProcessResult(imsegs(f), pg(tf));
    [vacc2, hacc2] = mcmcProcessResult(imsegs(f), pg2(tf));

    disp(['vacc: ' num2str(vacc1) '-->' num2str(vacc2) '   hacc: ' num2str(hacc1) '-->' num2str(hacc2)])
    
end

[vacc, hacc, vcm, hcm] = mcmcProcessResult(imsegs(cv_images), pg);
[vacc2, hacc2, vcm2, hcm2] = mcmcProcessResult(imsegs(cv_images), pg2);

save '/IUS/vmr20/dhoiem/data/ijcv06/saResults4.mat' 'vacc' 'hacc' 'vcm' 'hcm' 'vacc2' 'hacc2' 'vcm2' 'hcm2' 'smaps' 'pg' 'pg2' 'segs2' 'segpg2' 'e1' 'e2'

