% msTrain


LOAD = 0;

nsegments = [5 7 10 15 20 25 35 50 60 70 80 90 100 Inf]; % number of segments per segmentation
ncv = 1; % number of cross-validation sets (typically 1)
labeltol = 0.9; % required percentage of single-label pixels for segment to be good (default 0.9)
nclasses = 23;  % number of categories

imdir = '~/data/msrc/MSRC_ObjCategImageDatabase_v2/Images/';  % where the training/test images are stored
datadir = '~/data/eccv08/msrc21/';  % where existing data is stored
outdir = datadir;  % where to save data, results, etc.

if LOAD
    load(fullfile(datadir, 'trainTestFn.mat'));
    load(fullfile(datadir, 'msrc_imsegs.mat'));
    load(fullfile(datadir, 'trainLabels.mat'));
    load(fullfile(outdir, 'msSuperpixelLabels.mat'));
    load(fullfile(outdir, 'msSuperpixelData.mat'));
    load(fullfile(outdir, 'msEdgeData.mat'));
    load(fullfile(outdir, 'msEdgeClassifier.mat'));
end

% assume that imsegs structures have been created 
% See msCreateSuperpixels

% assume that "train" and "test" have been loaded, which include
% indices into imsegs for training and testing data
allind = union(train, test);
trainind1 = train(1:50);  % use first 50 training images to train segmentations
trainind = train;
trainind2 = setdiff(trainind, trainind1);
testind = test;

nimages = numel(imsegs);

% labels is a cell array of pixel maps, with values equal to the category (0 for unlabeled)
disp('Converting labels to superpixels')
if ~exist('splabels', 'var')
    splabels = msLabelMap2Sp(labels, {imsegs.segimage});  
    save(fullfile(outdir, 'msSuperpixelLabels.mat'), 'splabels');
end

disp('Getting superpixel features')
if ~exist('spfeatures', 'var')
    spfeatures = mcmcGetAllSuperpixelData(imdir, imsegs);
    save(fullfile(outdir, 'msSuperpixelData.mat'), 'spfeatures');
end

disp('Getting edge features')
if ~exist('efeatures', 'var')
    [efeatures, adjlist] = mcmcGetAllEdgeData(spfeatures, imsegs);
    save(fullfile(outdir, 'msEdgeData.mat'), 'efeatures', 'adjlist');
end

disp('Training edge classifier')
if ~exist('eclassifier', 'var')
    eclassifier = msTrainEdgeClassifier(efeatures(trainind1), ...
        adjlist(trainind1), imsegs(trainind1), splabels(trainind1));
    ecal = msCalibrateEdgeClassifier(efeatures(trainind2), adjlist(trainind2), ...
        imsegs(trainind2), eclassifier, splabels(trainind2), ncv);
    ecal = ecal{1};
    save(fullfile(outdir, 'msEdgeClassifier.mat'), 'eclassifier', 'ecal');
end

disp('Getting multiple segmentations')
if ~exist('smaps', 'var')
    for f = allind       
        pE{f} = test_boosted_dt_mc(eclassifier, efeatures{f});
        pE{f} = 1 ./ (1+exp(ecal(1)*pE{f}+ecal(2)));                
        smaps{f} = msCreateMultipleSegmentations(pE{f}, adjlist{f}, ...
            imsegs(f).nseg, nsegments);
    end
    save(fullfile(outdir, 'msMultipleSegmentations.mat'), 'pE', 'smaps');
end
    
disp('Getting segment features')
if ~exist('segfeatures', 'var')    
    for f = allind       
        if mod(f, 50)==0, disp(num2str(f)), end
        im = im2double(imread([imdir '/' imsegs(f).imname]));
        imdata = mcmcComputeImageData(im, imsegs(f));
    
        for k = 1:numel(nsegments)
            segfeatures{f, k} = mcmcGetSegmentFeatures(imsegs(f), ...
                spfeatures{f}, imdata, smaps{f}(:, k), (1:max(smaps{f}(:, k))));
            [mclab{f, k}, mcprc{f, k}, allprc{f, k}, trainw{f, k}] = ...
                msSegs2labels(imsegs(f), smaps{f}(:, k), splabels{f}, nclasses);
            seglabel{f, k} = mclab{f, k}.*(mcprc{f, k}>labeltol);
            seggood{f,k} =  1*(mcprc{f, k}>labeltol) + (-1)*(mcprc{f, k}<labeltol); 
        end    
    end 
    save(fullfile(outdir, 'msSegmentFeatures.mat'), 'segfeatures', 'seglabel', 'seggood', 'trainw');
end

disp('Training segmentation classifier')
if ~exist('segclassifier', 'var')
    traindata = segfeatures(trainind, :);
    trainlabels = seggood(trainind, :);
    trainweights = trainw(trainind, :);
    segclassifier = mcmcTrainSegmentationClassifier2(traindata, trainlabels, trainweights); 
    save(fullfile(outdir, 'msSegmentationClassifier.mat'), 'segclassifier');    
end

disp('Training label classifier')
if ~exist('labelclassifier', 'var')
    traindata = segfeatures(trainind, :);
    trainlabels = seglabel(trainind, :);    
    trainweights = trainw(trainind, :);
    labelclassifier = msTrainLabelClassifier(traindata, trainlabels, trainweights, classnames, Inf);
    %labelclassifier = mcmcTrainSegmentClassifier2(traindata, trainlabels, trainweights); 
    save(fullfile(outdir, 'msLabelClassifier.mat'), 'labelclassifier');    
end
    
save(fullfile(outdir, 'msClassifiers.mat'), 'eclassifier', 'segclassifier', 'labelclassifier', 'ecal');



