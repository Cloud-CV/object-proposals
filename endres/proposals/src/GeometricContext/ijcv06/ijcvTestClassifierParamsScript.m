
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';

if 0
    load '../data/allimsegs2.mat'
    load([outdir '/multisegTrain.mat'])
    load '../data/rand_indices.mat'
end

ntrees = [1 2 5 10 20 50 100];

ncv = 5;

if 0
disp('2 to 3')
for k = 2:3
    disp(['Iteration: ' num2str(k)]);
    testind{k} = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
    trainind{k} = setdiff([1:numel(cv_images)], testind{k});
    sclassifiert(k) = mcmcTrainSegmentationClassifier2(labdata(trainind{k}, :), ...
        seglabel(trainind{k}, :), trainw(trainind{k}, :), [], [8 ntrees(end) 0]);   
    [vclassifiert(k), hclassifiert(k)] = ...
        mcmcTrainSegmentClassifier2(labdata(trainind{k}, :), ...
        unilabel(trainind{k}, :), trainw(trainind{k}, :), 50000, [8 ntrees(end) 0]);       
end

save([outdir '/classifierParams2.mat'], 'vclassifiert', 'hclassifiert', 'sclassifiert')
for t = 1:numel(ntrees)
    for k = 1:ncv
        tmpvc(k) = vclassifiert(k);
        tmpvc(k).wcs = tmpvc(k).wcs(1:ntrees(t), :);
        tmphc(k) = hclassifiert(k);
        tmphc(k).wcs = tmphc(k).wcs(1:ntrees(t), :);        
        tmpsc(k) = sclassifiert(k);
        tmpsc(k).wcs = tmpsc(k).wcs(1:ntrees(t));           
    end
    [vacc_t(t), hacc_t(t)] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
        labdata, labdata, smaps, tmpvc, tmphc, tmpsc, pvSP, phSP, ncv);
    disp(num2str(vacc_t))
    disp(num2str(hacc_t))
end        
save([outdir '/classifierParams2.mat'], 'nnodes', 'ntrees', 'vacc_t', 'hacc_t', 'vclassifiert', 'hclassifiert', 'sclassifiert')
end % end if 0

if 1
nnodes = [2 4 8 16 32];

disp('starting at 2')

[vacc_n(n), hacc_n(n)] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
    labdata, labdata, smaps, vclassifier, hclassifier, sclassifier, pvSP, phSP, ncv);
disp(num2str([vacc_n ; hacc_n])) 
for n = 2:numel(nnodes)
    disp([num2str(nnodes(n)) ' nodes'])
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind{k} = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind{k} = setdiff([1:numel(cv_images)], testind{k});
        sclassifier(k) = mcmcTrainSegmentationClassifier2(labdata(trainind{k}, :), ...
            seglabel(trainind{k}, :), trainw(trainind{k}, :), [], [nnodes(n) 160/nnodes(n) 0]);   
        [vclassifier(k), hclassifier(k)] = ...
            mcmcTrainSegmentClassifier2(labdata(trainind{k}, :), ...
            unilabel(trainind{k}, :), trainw(trainind{k}, :), 50000, [nnodes(n) 160/nnodes(n) 0]);                        
    end
    [vacc_n(n), hacc_n(n)] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
        labdata, labdata, smaps, vclassifier, hclassifier, sclassifier, pvSP, phSP, ncv);
    disp(num2str([vacc_n ; hacc_n])) 
end
save([outdir '/classifierParamsNodes.mat'], 'nnodes', 'vacc_n', 'hacc_n', 'vclassifier', 'hclassifier', 'sclassifier')
end