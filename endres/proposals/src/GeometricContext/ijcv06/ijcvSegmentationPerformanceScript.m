% ijcvSegmentationPerformanceScript

outdir = '/IUS/vmr20/dhoiem/data/ijcv06';

tmp = load([outdir '/multisegTrain.mat']);
seglabel = tmp.seglabel;
mcprc = tmp.mcprc;
segdata = tmp.segdata;
labdata = tmp.labdata;
trainw =tmp.trainw;

tmp = load([outdir '/multisegResults.mat']);
sclassifier = tmp.sclassifier;
sclassifier2 = tmp.sclassifier2;
% for k = 1:ncv
%     testind = (floor((k-1)*numel(cv_images)/ncv)+1):(floor(k*numel(cv_images)/ncv));
%     trainind = setdiff([1:numel(cv_images)], testind);
%     sclassifier2(k) = mcmcTrainSegmentationClassifier2(labdata(trainind, :), seglabel(trainind, :), trainw(trainind, :));             
% end    
 
segres1 = mcmcTestSegmentationClassifierCV2(sclassifier, segdata, seglabel);
segres2 = mcmcTestSegmentationClassifierCV2(sclassifier2, labdata, seglabel);

save([outdir '/segClassifierResults.mat'], 'segres1', 'segres2');

