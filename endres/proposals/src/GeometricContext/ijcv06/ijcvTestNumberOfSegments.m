% ijcvTestNumberOfSegments
 
imdir = '../images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
ncv = 5;

if 0
    load '../data/allimsegs2.mat';
    load '../data/rand_indices.mat';    
    load '../data/mcmcEdgeClassifier.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData.mat'
    tmp = load([outdir '/multisegResults2.mat']);
    vclassifier = tmp.vclassifier;
    hclassifier = tmp.hclassifier;
    sclassifier = tmp.sclassifier2;
    tmp = load([outdir '/multisegTrain.mat']);
    pvSP = tmp.pvSP;
    phSP = tmp.phSP;
    pE = tmp.pE;
    clear tmp
end

nsegments = repmat([5 10 15 20 25 30 35 40 45 50 60 70 80 90 100], [1 4]);

segind{1} = [2:4:15]; % 1/4 as many
segind{2} = [1:2:15]; % 1/2 as many
segind{3} = [1:15];   
segind{4} = [1:30];
segind{5} = [1:60];

if 0
% gather data
for tf = 1:numel(cv_images)

    f = cv_images(tf);

    c = ceil(tf/numel(cv_images)*ncv);

    disp([num2str(tf) ': ' imsegs(f).imname])

    smaps{tf} = generateMultipleSegmentations2(pE{tf}, adjlist{f}, imsegs(f).nseg, nsegments);

    im = im2double(imread([imdir '/' imsegs(f).imname]));
    imdata = mcmcComputeImageData(im, imsegs(f));

    for k = 1:numel(nsegments)
        labdata{tf, k} = mcmcGetSegmentFeatures(imsegs(f), spfeatures{f}, imdata, smaps{tf}(:, k), (1:max(smaps{tf}(:, k))));
        %segdata{tf, k} = mcmcGetSegmentationFeatures(pvSP{tf}, phSP{tf}, pE{tf}, adjlist{f}, imsegs(f).npixels, smaps{tf}(:, k), (1:max(smaps{tf}(:, k))));                                
    end
end
save([outdir '/manySegmentationsTrain.mat'], 'labdata', 'nsegments', 'segind', 'smaps');
end

load([outdir '/manySegmentationsTrain.mat']);
load([outdir '/numSegmentationsResults.mat']);
segind{6} = [10];
segind{7} = [6 12];
disp('adding 1 and 2')
for k = 6:numel(segind)
    tmpmaps = smaps;    
    for f = 1:numel(smaps)
        tmpmaps{f} = smaps{f}(:, segind{k});
    end
       
    [vacc(k), hacc(k), pg{k}] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
        labdata(:, segind{k}), labdata(:, segind{k}), tmpmaps, vclassifier, hclassifier, sclassifier, pvSP, phSP, ncv);    
    disp(num2str([vacc ; hacc]))
end    

save([outdir '/numSegmentationsResults.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'pg')