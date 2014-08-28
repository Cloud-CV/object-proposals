% ijcvTestFeaturesScript
 
imdir = '../images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
ncv = 5;


if 1
    load '../data/rand_indices.mat'
    load '../data/allimsegs2.mat'    
    load '../data/mcmcEdgeClassifier.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData.mat'    
    load('/IUS/vmr20/dhoiem/data/ijcv06/multisegTrain.mat');
    
end

%nsegments = [3 5 6 6 7 8 9 10 11 12 13 14 15 17 18 20 23 27 32 45 50 75 100];
%nsegments = [3 4 5 6 7 7 8 8 9 9 10 11 11 12 12 13 13 14 14 15 16 16 17 19 20 21 23 25 28 31 37 51];

fset{1} = [45:50 53:54 73:75];
fset{2} = [1:14];
fset{3} = [15:44];
fset{4} = [51:52 57:72 76:94];

if 1

for f = 1:4
    currf = fset{f};
    
    tmpdata = labdata;
    for k = 1:numel(labdata)
        tmpdata{k} = labdata{k}(:, currf);
    end
    
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind = setdiff([1:numel(cv_images)], testind);   
        sclassifier(f, k) = mcmcTrainSegmentationClassifier2(tmpdata(trainind, :), seglabel(trainind, :), trainw(trainind, :)); 
        [vclassifier(f, k), hclassifier(f, k)] = ...
            mcmcTrainSegmentClassifier2(tmpdata(trainind, :), unilabel(trainind, :), trainw(trainind, :), 50000);       
    end        
    [vacc(f), hacc(f), tmp1, tmp2, pg{f}] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
        tmpdata, tmpdata, smaps, vclassifier(f, :), hclassifier(f, :), sclassifier(f, :), pvSP, phSP, ncv);
    disp(num2str([vacc ; hacc]))    
end
save([outdir '/featureResultsSingle2.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'pg');


end

if 0

for f = 1:4
    currf = setdiff(cat(2, fset{:}), fset{f});
    
    tmpdata = labdata;
    for k = 1:numel(labdata)
        tmpdata{k} = labdata{k}(:, currf);
    end
    
    for k = 1:ncv
        disp(['Iteration: ' num2str(k)]);
        testind = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
        trainind = setdiff([1:numel(cv_images)], testind);   
        sclassifier(f, k) = mcmcTrainSegmentationClassifier2(tmpdata(trainind, :), seglabel(trainind, :), trainw(trainind, :)); 
        [vclassifier(f, k), hclassifier(f, k)] = ...
            mcmcTrainSegmentClassifier2(tmpdata(trainind, :), unilabel(trainind, :), trainw(trainind, :), 50000);       
    end        
    [vacc(f), hacc(f), pg{f}] = testMultipleSegmentationsCV2(imsegs(cv_images), ...
        tmpdata, tmpdata, smaps, vclassifier(f, :), hclassifier(f, :), sclassifier(f, :), pvSP, phSP, ncv);
    disp(num2str([vacc ; hacc]))
    save([outdir '/featureResultsMultiple.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'vacc', 'hacc', 'pg');
end
  
end

