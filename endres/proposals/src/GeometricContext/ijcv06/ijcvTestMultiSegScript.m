% ijcvMultiSegScript
 
imdir = '../images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
ncv = 5;

if 1
    load '../data/rand_indices.mat'
    load '../data/mcmcEdgeClassifier2.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData2.mat'
end

nsegments = [5 10 15 20 25 30 35 40 45 50 60 70 80 90 100];
%nsegments = [3 5 6 6 7 8 9 10 11 12 13 14 15 17 18 20 23 27 32 45 50 75 100];
%nsegments = [3 4 5 6 7 7 8 8 9 9 10 11 11 12 12 13 13 14 14 15 16 16 17 19 20 21 23 25 28 31 37 51];

if ~exist('labdata')
    % gather data
    for tf = 1:numel(cv_images)

        f = cv_images(tf);

        c = ceil(tf/numel(cv_images)*ncv);
        
        disp([num2str(tf) ': ' imsegs(f).imname])

        [pvSP{tf}, phSP{tf}, pE{tf}] = mcmcInitialize(spfeatures{f}, efeatures{f}, ...
            adjlist{f}, imsegs(f), vclassifierSP, hclassifierSP, eclassifier, ecal{c}, 'none');
        smaps{tf} = generateMultipleSegmentations2(pE{tf}, adjlist{f}, imsegs(f).nseg, nsegments);

        im = im2double(imread([imdir '/' imsegs(f).imname]));
        imdata = mcmcComputeImageData(im, imsegs(f));

        for k = 1:numel(nsegments)
            labdata{tf, k} = mcmcGetSegmentFeatures(imsegs(f), spfeatures{f}, imdata, smaps{tf}(:, k), (1:max(smaps{tf}(:, k))));
            segdata{tf, k} = mcmcGetSegmentationFeatures(pvSP{tf}, phSP{tf}, pE{tf}, adjlist{f}, imsegs(f).npixels, smaps{tf}(:, k), (1:max(smaps{tf}(:, k))));
            [mclab{tf, k}, mcprc{tf, k}, allprc{tf, k}, trainw{tf, k}] = segmentation2labels(imsegs(f), smaps{tf}(:, k));
            unilabel{tf, k} = mclab{tf, k}.*(mcprc{tf, k}>0.95);
            seglabel{tf,k} =  1*(mcprc{tf, k}>0.95) + (-1)*(mcprc{tf, k}<0.95);                                  
        end
    end
    save([outdir '/multisegTrain.mat'], 'smaps', 'labdata', 'segdata', 'mclab', 'mcprc', 'allprc', 'seglabel', 'unilabel', 'trainw', 'pvSP', 'phSP', 'pE');
end

if ~exist('vclassifier')
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind{k} = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind{k} = setdiff([1:numel(cv_images)], testind{k});
        sclassifier(k) = mcmcTrainSegmentationClassifier2(segdata(trainind{k}, :), seglabel(trainind{k}, :), trainw(trainind{k}, :));   
        sclassifier2(k) = mcmcTrainSegmentationClassifier2(labdata(trainind{k}, :), seglabel(trainind{k}, :), trainw(trainind{k}, :)); 
        [vclassifier(k), hclassifier(k)] = ...
            mcmcTrainSegmentClassifier2(labdata(trainind{k}, :), unilabel(trainind{k}, :), trainw(trainind{k}, :), 50000);       
    end
end
[vacc, hacc, vcm, hcm, pg] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
    labdata, segdata, smaps, vclassifier, hclassifier, sclassifier, pvSP, phSP, ncv);
[vacc2, hacc2, vcm2, hcm2, pg2] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
    labdata, labdata, smaps, vclassifier, hclassifier, sclassifier2, pvSP, phSP, ncv);    

save([outdir '/multisegResults2.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'sclassifier2', 'vacc', 'hacc', 'vcm', 'hcm', 'pg', 'smaps', 'vacc2', 'hacc2', 'vcm2', 'hcm2', 'pg2');