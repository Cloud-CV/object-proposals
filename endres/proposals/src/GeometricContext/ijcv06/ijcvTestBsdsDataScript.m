% ijcvMultiSegScript
 
imdir = '../images/tmp';
outdir = '../data';
ncv = 5;

if 0
    load '../data/allimsegs2.mat';
    load '../data/rand_indices.mat'
    load '../data/mcmcEdgeClassifier2.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData2.mat'
    load '../data/bsdssegs.mat';
    load '../data/ijcv06/multisegTrain.mat';
    %load '../data/bsdsdata.mat';
end

nsegments = [5 10 15 20 25 30 35 40 45 50 60 70 80 90 100];

if ~exist('spfeatures_bs')
    spfeatures_bs = mcmcGetAllSuperpixelData(imdir, bsdssegs);
    [efeatures_bs, adjlist_bs] = mcmcGetAllEdgeData(spfeatures_bs, bsdssegs);
    for f = 1:numel(bsdssegs)
        fprintf(1, '.', int32(f))
        if mod(f, 25)==0, fprintf(1, '\n'); end
        
        [pvSP_bs{f}, phSP_bs{f}, pE_bs{f}] = mcmcInitialize(spfeatures_bs{f}, efeatures_bs{f}, ...
            adjlist_bs{f}, bsdssegs(f), vclassifierSP, hclassifierSP, eclassifier, ecal{1}, 'none');
        smaps_bs{f} = generateMultipleSegmentations2(pE_bs{f}, adjlist_bs{f}, bsdssegs(f).nseg, nsegments);

        im = im2double(imread([imdir '/' bsdssegs(f).imname]));
        imdata = mcmcComputeImageData(im, bsdssegs(f));

        for k = 1:numel(nsegments)
            labdata_bs{f, k} = mcmcGetSegmentFeatures(bsdssegs(f), spfeatures_bs{f}, imdata, smaps_bs{f}(:, k), (1:max(smaps_bs{f}(:, k))));            
            [mclab_bs{f, k}, mcprc_bs{f, k}, allprc_bs{f, k}, trainw_bs{f, k}] = segmentation2labels(bsdssegs(f), smaps_bs{f}(:, k));
            unilabel_bs{f, k} = mclab_bs{f, k}.*(mcprc_bs{f, k}>0.95);
            seglabel_bs{f,k} =  1*(mcprc_bs{f, k}>0.95) + (-1)*(mcprc_bs{f, k}<0.95);                                  
        end        
    end
    
    save([outdir '/bsdsdata.mat'], 'spfeatures_bs', 'efeatures_bs', 'adjlist_bs', ...
        'pvSP_bs', 'phSP_bs', 'pE_bs', 'smaps_bs', 'labdata_bs', ...
        'mclab_bs', 'mcprc_bs', 'allprc_bs', 'seglabel_bs', 'unilabel_bs', ...
        'trainw_bs');
end
%nsegments = [3 5 6 6 7 8 9 10 11 12 13 14 15 17 18 20 23 27 32 45 50 75 100];
%nsegments = [3 4 5 6 7 7 8 8 9 9 10 11 11 12 12 13 13 14 14 15 16 16 17 19 20 21 23 25 28 31 37 51];


if ~exist('vclassifier')
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind{k} = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind{k} = setdiff([1:numel(cv_images)], testind{k});
        sclassifier(k) = mcmcTrainSegmentationClassifier2(...
            [labdata(trainind{k}, :) ; labdata_bs], ...
            [seglabel(trainind{k}, :) ; seglabel_bs], ...
            [trainw(trainind{k}, :) ; trainw_bs]); 
        [vclassifier(k), hclassifier(k)] = ...
            mcmcTrainSegmentClassifier2(...
            [labdata(trainind{k}, :) ; labdata_bs], ...
            [unilabel(trainind{k}, :) ; unilabel_bs], ...
            [trainw(trainind{k}, :) ; trainw_bs], 100000);       
    end
end
[vacc, hacc, vcm, hcm, pg] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
    labdata, labdata, smaps, vclassifier, hclassifier, sclassifier, pvSP, phSP, ncv);  

save([outdir '/addBsdsResults.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'vcm', 'hcm', 'pg', 'smaps');