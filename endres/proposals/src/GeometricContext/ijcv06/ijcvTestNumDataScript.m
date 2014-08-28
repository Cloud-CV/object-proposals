% ijcvTestNumDataScript
 
imdir = '../images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
ncv = 5;


if 0
    load '../data/rand_indices.mat'
    load '../data/allimsegs2.mat'    
    load '../data/mcmcEdgeClassifier.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData.mat'    
    load('/IUS/vmr20/dhoiem/data/ijcv06/multisegTrain.mat');    
    tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/multisegResults2.mat');    
end

numtrain = [5 10 25 50 75 100 150 200];
  
 
for nt = 1:(numel(numtrain)-1)
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind = setdiff([1:numel(cv_images)], testind);   
        rind = randperm(numel(trainind));    
        tmpind = trainind(rind(1:numtrain(nt)));        
        sclassifier(nt,k) = mcmcTrainSegmentationClassifier2(labdata(tmpind, :), seglabel(tmpind, :), trainw(tmpind, :)); 
        [vclassifier(nt,k), hclassifier(nt,k)] = ...
            mcmcTrainSegmentClassifier2(labdata(tmpind, :), unilabel(tmpind, :), trainw(tmpind, :), 50000);             
    end        
    [vacc(nt), hacc(nt), pg{nt}] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
        labdata, labdata, smaps, vclassifier(nt, :), hclassifier(nt, :), sclassifier(nt, :), pvSP, phSP, ncv); 
    disp(num2str([vacc ; hacc]))
    save([outdir '/ndataResults2.mat'], 'numtrain', 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'pg');
end

vacc(nt+1) = tmp.vacc2;
hacc(nt+1) = tmp.hacc2;
pg{nt+1} = tmp.pg2;
save([outdir '/ndataResults2.mat'], 'numtrain', 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'pg');

