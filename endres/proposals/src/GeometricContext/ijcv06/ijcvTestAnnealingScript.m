%function [pg, energy, map, allenergy] = mcmcEvaluate(imsegs, imdir, vclassifierSP, hclassifierSP, ...
%    eclassifier, ecal, vclassifier, hclassifier, sclassifier, spdata, adjlist, edata)

DO_LOAD = 0;

if DO_LOAD
    clear
    load '../data/allimsegs2.mat';
    load '../data/rand_indices.mat';
    load '../data/mcmcEdgeData.mat';
    load '../data/mcmcEdgeClassifier.mat';
    load '../data/mcmcSuperpixelData.mat';
    load '../data/mcmcSuperpixelClassifier.mat';    
    tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/spSegResults2.mat');
    %tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/multisegResults.mat');
    vclassifier = tmp.vclassifier;
    hclassifier = tmp.hclassifier;
    load('/IUS/vmr20/dhoiem/data/mcmcdata/segmentationRegressionTree.mat');
    clear tmp;
end

imdir = '/IUS/vmr7/dhoiem/context/images/all_images';

ncv = numel(vclassifier);

maxIter = 40;

vacc = zeros(numel(imsegs), 1);
hacc = zeros(numel(imsegs), 1);

%load '../data/tmp.mat'
  
for tf = 1:numel(cv_images)
    
    f = cv_images(tf);
    
    c = ceil(f/numel(imsegs)*ncv);
    
    disp([num2str(tf) ': ' imsegs(f).imname])
    
    im = im2double(imread([imdir '/' imsegs(f).imname]));
    
    [pg{tf}, smaps{tf}] = mcmcTestImageSA(im, imsegs(f), ...
        vclassifierSP, hclassifierSP, eclassifier, ecal{c}, vclassifier(c), hclassifier(c), ...
        segdt(c), maxIter, spfeatures{f}, adjlist{f}, efeatures{f});
    [vacc1, hacc1] = mcmcProcessResult(imsegs(f), tmp.pg(tf));
    [vacc2, hacc2] = mcmcProcessResult(imsegs(f), pg(tf));
    %energy(f) = allenergy{f}(end);     
   
    %save '../data/tmp.mat' pg vacc hacc vtotal htotal energy

    %disp('***** Report *****') ;
    %disp('Total')
    disp(['vacc: ' num2str(vacc1) '-->' num2str(vacc2) '   hacc: ' num2str(hacc1) '-->' num2str(hacc2)])
    %disp('*** End Report ***');
    
end

[vacc, hacc, vcm, hcm] = mcmcProcessResult(imsegs(cv_images), pg);

save '/IUS/vmr20/dhoiem/data/ijcv06/saResults.mat' 'vacc' 'hacc' 'vcm' 'hcm' 'smaps' 'pg'

