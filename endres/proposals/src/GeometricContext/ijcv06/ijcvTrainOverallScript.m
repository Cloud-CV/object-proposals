% ijcvMultiSegScript
 
imdir = '../images/all_images';
outdir = '/usr1/projects/GeometricContext/data/ijcv06/';
ncv = 5;

if 0    
    disp('training outdoor')
    load '../data/mcmcEdgeClassifier.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData.mat'
    load([outdir '/multisegTrain.mat']);
end
if 1
    disp('training indoor')
    tmp = load('../data/ijcv06/ijcvClassifier.mat');
    eclassifier = tmp.eclassifier;
    load '../data/indoordata.mat';
    
    % remove some of the segmentations
    seginds = [2 4 5 8 10 11 13 15];
    labdata = labdata(:, seginds);
    trainw = trainw(:, seginds);
    seglabel = seglabel(:, seginds);
    unilabel = unilabel(:, seginds);
end


sclassifier = mcmcTrainSegmentationClassifier2(labdata, seglabel, trainw, 75000, [8 15 0]); 
[vclassifier, hclassifier] = mcmcTrainSegmentClassifier2(labdata, unilabel, trainw, 75000, [8 15 0]);       

save([outdir '/ijcvClassifier_indoor.mat'], 'vclassifier', 'hclassifier', 'sclassifier', 'eclassifier');