% labelmePrepareData
DO_DB = 0;
DO_LABELS = 0;
DO_TRANSFER_BMAPS = 0;
GET_TRAINING_DATA = 1;

addpath('~/src/labelme');

set = 'train'; % train, test

basedir = '~/data/occlusion/labelme';
imdir = fullfile(basedir, set, 'Images');
anndir = fullfile(basedir, set, 'Annotations');
labeldir = fullfile(basedir, 'labels2');

if DO_DB
    outdir = basedir;
    db = LMdatabase(anndir);
    save(fullfile(outdir, [set '_db']), 'db');
end

if DO_LABELS        
    filestr = '*.xml';
    maxsize = 1024;
    outdir = fullfile(basedir, 'labels3');
    ignoreparts = true;
    processDirectory(anndir, filestr, outdir, '_labels.mat', ...
        @processIm2LabelmeLabels, imdir, maxsize, ignoreparts);         
%     load(fullfile(outdir, [set '_db']));
%     parfor k = 1:numel(db)
%         [lim{k}, objnames{k}] = annotation2labels(db(k).annotation, imdir, 1024);
%     end
%     save(fullfile(outdir, [set '_labels']), 'lim', 'objnames');
end

if DO_TRANSFER_BMAPS
    setOcclusionDirectories;
    %load(fullfile(basedir, [set '_db']));
    isFullyLabeled = false(size(db));
    
    for k = 1:numel(db)
        
        
        if mod(k, 100)==0
            disp(num2str(k));
        end
        try            
            folder = db(k).annotation.folder;
            bn = strtok(db(k).annotation.filename, '.');
            occfn = fullfile(occdir, folder, [bn '_occlusion']);
            labelfn = fullfile(labeldir, folder, [bn '_labels']);
            load(occfn, 'bndinfo_all');
            load(labelfn, 'lim');        

            if mean(lim(:)>0)>0.97 % fully labeled

                isFullyLabeled(k) = true;                
                
                % resize object segmentation image to be same size as 
                [imh, imw] = size(bndinfo_all{1}.wseg);
                lim = imresize(lim, [imh imw], 'nearest');        

                % get distance of pixels from ground truth boundary
                gtmap = seg2bmap(lim, imw, imh);
                gtdist = bwdist(gtmap);
                maxdist = 0.01*sqrt(imh.^2+imw.^2);

                ne = bndinfo_all{1}.ne;
                labels{k} = false(ne, 1);
                labels_near{k} = false(ne, 1);

                [lab, labim, err] = transferRegionLabels(lim, double(bndinfo_all{1}.wseg));
                for k2 = 1:ne
                    LR = bndinfo_all{1}.edges.spLR(k2, :);
                    labels{k}(k2) = lab(LR(1))~=lab(LR(2));
                    labels_near{k}(k2) = labels{k}(k2) && ...
                        (mean(gtdist(bndinfo_all{1}.edges.indices{k2}))<maxdist);
                end
            end
        catch
            disp(lasterr);
        end
    end
    save(fullfile(traindir, 'tranferredBoundaryLabels.mat'), 'labels', 'labels_near', 'isFullyLabeled');
    
end

if GET_TRAINING_DATA
    
    %N = 1000; % number of pixels per image to sample
    
    %load(fullfile(basedir, [set '_db']));
    load(fullfile(traindir, 'tranferredBoundaryLabels.mat'));
    x = cell(numel(labels_near), 1);
    y = cell(numel(labels_near), 1);
    for k = 1:numel(labels_near)
        
        if mod(k, 100)==0
            disp(num2str(k));
        end
        
        if isFullyLabeled(k)
        
            folder = db(k).annotation.folder;
            bn = strtok(db(k).annotation.filename, '.');
                
            occfn = fullfile(occdir, folder, [bn '_occlusion']);        
            load(occfn, 'bndinfo_all');
            y{k} = labels_near{k};
            y{k} = 2*y{k}-1; % convert to {-1, 1}
                  
            % set label of pixels near border to 0
            brd = 10;
            ind  = getBoundaryCenterIndices(bndinfo_all{1});            
            [yk, xk] = ind2sub(ind, occ.bndinfo.imsize(1:2));            
            valid = (yk>brd) & (yk <= occ.bndinfo_all{1}.imsize(1)-brd) & ...
                (xk > brd) & (xk <=occ.bndinfo_all{1}.imsize(2)-brd);
            y{k}(~valid) = 0;
            
            occ.po_all = getOcclusionMaps(bndinfo_all);
            x{k} = getBoundaryEdgletFeatures(bndinfo_all, occ);
        end
        
    end
    x = cat(1, x{:});
    y = cat(1, y{:});
    featDescription = {'pocc1', 'pocc2', 'pocc3', 'pocc4', 'pocc_max'};
    save(fullfile(traindir, 'trainData.mat'), 'x', 'y', 'featDescription');
end
        

