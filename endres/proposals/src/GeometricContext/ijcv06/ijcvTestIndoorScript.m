% ijcvMultiSegScript
 
imdir = '../images/stanford';
outdir = '../data';
ncv = 5;

if 1
    load '../data/stanford_imsegs2.mat';
    ijcv = load('../data/ijcv06/ijcvClassifier.mat');
    %load '../data/bsdsdata.mat';
end

cv_images = [1:numel(imsegs)];
nsegments = [5 10 15 20 25 30 35 40 45 50 60 70 80 90 100];

if ~exist('spfeatures')
    spfeatures = mcmcGetAllSuperpixelData(imdir, imsegs);
    [efeatures, adjlist] = mcmcGetAllEdgeData(spfeatures, imsegs);
    for f = 1:numel(imsegs)
        fprintf(1, '.', int32(f))
        if mod(f, 25)==0, fprintf(1, '\n'); end
        
        [pvSP{f}, phSP{f}, pE{f}] = mcmcInitialize(spfeatures{f}, efeatures{f}, ...
            adjlist{f}, imsegs(f), ijcv.vclassifierSP, ijcv.hclassifierSP, ijcv.eclassifier, ijcv.ecal, 'none');
        smaps{f} = generateMultipleSegmentations2(pE{f}, adjlist{f}, imsegs(f).nseg, nsegments);

        im = im2double(imread([imdir '/' imsegs(f).imname]));
        imdata = mcmcComputeImageData(im, imsegs(f));

        for k = 1:numel(nsegments)
            labdata{f, k} = mcmcGetSegmentFeatures(imsegs(f), spfeatures{f}, imdata, smaps{f}(:, k), (1:max(smaps{f}(:, k))));            
            [mclab{f, k}, mcprc{f, k}, allprc{f, k}, trainw{f, k}] = segmentation2labels(imsegs(f), smaps{f}(:, k));
            unilabel{f, k} = mclab{f, k}.*(mcprc{f, k}>0.95);
            seglabel{f,k} =  1*(mcprc{f, k}>0.95) + (-1)*(mcprc{f, k}<0.95);                                  
        end        
    end
    
    save([outdir '/indoordata.mat'], 'spfeatures', 'efeatures', 'adjlist', ...
        'pvSP', 'phSP', 'pE', 'smaps', 'labdata', ...
        'mclab', 'mcprc', 'allprc', 'seglabel', 'unilabel', ...
        'trainw');
end
%nsegments = [3 5 6 6 7 8 9 10 11 12 13 14 15 17 18 20 23 27 32 45 50 75 100];
%nsegments = [3 4 5 6 7 7 8 8 9 9 10 11 11 12 12 13 13 14 14 15 16 16 17 19 20 21 23 25 28 31 37 51];

[vacc, hacc, vcm, hcm, pg] = testMultipleSegmentationsCV2(imsegs, ...
    labdata, labdata, smaps, ijcv.vclassifier, ijcv.hclassifier, ijcv.sclassifier, ...
    pvSP, phSP, 1);
save([outdir '/indoorResults_trainOutdoor.mat'], 'vacc', 'hacc', 'vcm', 'hcm', 'pg');
disp(num2str([vacc hacc]))
disp(num2str(vcm))
disp(num2str(hcm))

if ~exist('vclassifier')
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind{k} = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind{k} = setdiff([1:numel(cv_images)], testind{k});
        sclassifier(k) = mcmcTrainSegmentationClassifier2(...
            [labdata(trainind{k}, :) ; labdata], ...
            [seglabel(trainind{k}, :) ; seglabel], ...
            [trainw(trainind{k}, :) ; trainw]); 
        [vclassifier(k), hclassifier(k)] = ...
            mcmcTrainSegmentClassifier2(...
            [labdata(trainind{k}, :) ; labdata], ...
            [unilabel(trainind{k}, :) ; unilabel], ...
            [trainw(trainind{k}, :) ; trainw], 100000);       
    end
end
[vacc, hacc, vcm, hcm, pg] = testMultipleSegmentationsCV2(imsegs, ...
    labdata, labdata, smaps, vclassifier, hclassifier, sclassifier, [], [], ncv);  
disp(num2str([vacc hacc]))
disp(num2str(vcm))
disp(num2str(hcm))

save([outdir '/indoorResults.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'vcm', 'hcm', 'pg');