% bsdsPrepareData
DO_FN = 0;
DO_BMAPS = 0;
DO_TRANSFER_BMAPS = 0;
GET_TRAINING_DATA = 1;

bsdsdir = '~dhoiem/data/datasets/BSDS300/';
imdir = fullfile(bsdsdir, 'images/all/');

basedir = '~/data/occlusion/bsds';
gtdir = fullfile(basedir, 'gt');
occdir = fullfile(basedir, 'occlusion');
pbdir = fullfile(basedir, 'pb');
pb2dir = fullfile(basedir, 'pb2');
traindir = fullfile(basedir, 'train');

testids = load([bsdsdir 'iids_test.txt']);
trainids = load([bsdsdir 'iids_train.txt']);
imfn = dir(fullfile(imdir, '*.jpg'));
imfn = {imfn.name};

%% get train and test indices
if DO_FN    
    test = [];
    for k = 1:numel(testids)
        test(k) = find(strcmp(imfn, [num2str(testids(k)) '.jpg']));
    end
    train = [];
    for k = 1:numel(trainids)
        train(k) = find(strcmp(imfn, [num2str(trainids(k)) '.jpg']));
    end
    save(fullfile(gtdir, 'trainTestFn.mat'), 'train', 'test', 'imfn');
end

if DO_BMAPS
    load(fullfile(gtdir, 'trainTestFn.mat'));
    for k = 1:numel(imfn)
        if any(train==k)
            iid = trainids(find(train==k));
        else
            iid = testids(find(test==k));
        end
        [segs,uids] = readSegs('color', iid);
        labels{k} = zeros(size(segs{1}));
        for k2 = 1:numel(segs)
            bmap = seg2bmap(segs{k2});
            labels{k} = labels{k} + double(bmap);
        end
        labels{k} = double(labels{k});

        ind1 = labels{k}>=1;
        vals = labels{k}(ind1);
        ind0 = labels{k}==0;
        filw = floor(0.01*(sqrt(size(bmap,1).^2+size(bmap,2).^2)));
        bmap2 = imfilter(labels{k}, ones(filw))>0;
        labels{k}(ind0) = -1;
        labels{k}(bmap2) = 0;
        labels{k}(ind1) = vals;        
    end
    save(fullfile(gtdir, 'trainLabels.mat'), 'labels');
end

if DO_TRANSFER_BMAPS
    load(fullfile(gtdir, 'trainTestFn.mat'));
    orig = load(fullfile(gtdir, 'trainLabels.mat'), 'labels');    
    for k = 1:numel(imfn)
        disp(num2str(k));
        if any(train==k)
            iid = trainids(train==k);
        else
            iid = testids(test==k);
        end
        
        load(fullfile(occdir, [num2str(iid) '_occlusion']));
        
        [segs,uids] = readSegs('color', iid);
       
        edgemap{k} = false(size(segs{1}));        
        for k2 = 1:numel(bndinfo_all{1}.edges.indices)
            edgemap{k}(bndinfo_all{1}.edges.indices{k2}) = true;
        end
        
        labels{k} = zeros(size(segs{1}));
        for k2 = 1:numel(segs)
            [lab, labim, err] = transferRegionLabels(segs{k2}, double(bndinfo_all{1}.wseg));
            bmap = zeros(size(edgemap{k}));
            for k3 = 1:numel(bndinfo_all{1}.edges.indices)
                LR = bndinfo_all{1}.edges.spLR(k3, :);
                bmap(bndinfo_all{1}.edges.indices{k3}) = lab(LR(1))~=lab(LR(2));
            end                        
            %bmap = seg2bmap(labim);
            labels{k} = labels{k} + double(bmap); 
        end        
        % enforce that positive labels are near ground truth boundary
        labels_near{k} = labels{k};
        labels_near{k}(orig.labels{k}<0)=0;                
    end   
    save(fullfile(gtdir, 'tranferredBoundaryLabels.mat'), 'labels', 'labels_near', 'edgemap');
end

if GET_TRAINING_DATA
    
    N = 1000; % number of pixels per image to sample
    
    load(fullfile(gtdir, 'trainTestFn.mat'));
    load(fullfile(gtdir, 'tranferredBoundaryLabels.mat'));
    for k = 1:numel(train)
        iid = trainids(k);
        
        n = train(k);
        lab = labels_near{n};
        idx = find(edgemap{n}(:))';
        
        % randomly sample pixels, with multiply labeled positive more
        % likely                        
        ind = cell(max(lab(:)), 1);
        ind{1} = idx;
        for k2 = 2:max(lab(:))
            ind{k2} = idx(lab(idx)>=k2);
        end
        ind = cat(2, ind{:});
        rp = randperm(numel(ind));
        ind = ind(rp(1:N));
        
        y{k} = lab(ind)>0;
        y{k} = y{k}(:);
        
        occ = load(fullfile(occdir, [num2str(iid) '_occmap']));
        pb = load(fullfile(pbdir, [num2str(iid) '_pb']));
        pb2 = load(fullfile(pb2dir, [num2str(iid) '_pb2']));
        
        [x{k}, featDescription] = getBoundaryFeatures(ind, occ, pb, pb2);
        
        disp(num2str(mean(x{k}(y{k}==1, :), 1) ./ mean(x{k}(y{k}==0, :), 1)))
        
    end
    featDescription = {'pocc1', 'pocc2', 'pocc3', 'pocc4', 'pocc_max', 'pb1', 'pb2'};
    save(fullfile(traindir, 'trainData.mat'), 'x', 'y', 'featDescription');
end
        
