function processLabelMeBoundaryLabels(inname, outname, varargin)
% Load occlusions and label image, transfer to superpixels from occlusion
% data, and compute boundary labels
% inname: name of xml annotation file (contains directory and filename)

%% Set parameters

occdir = varargin{1};
labeldir = varargin{2};

%% Read annotation
%annfn = fullfile(anndir, [inname(1:end-4) '.xml']);
db = loadXML(inname);

occfn = fullfile(occdir, db.annotation.folder, db.annotation.filename);
labelfn = fullfile(labeldir, db.annotation.folder, db.annotation.filename);

load(occfn);
load(labelfn);

       
labels{k} = zeros(size(segs{1}));
[lab, labim, err] = transferRegionLabels(lim, double(bndinfo_all{1}.wseg));
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

[lim, objnames] = annotation2labels(db.annotation, imdir, maxsize, ignoreparts);
save(outname, 'lim', 'objnames');