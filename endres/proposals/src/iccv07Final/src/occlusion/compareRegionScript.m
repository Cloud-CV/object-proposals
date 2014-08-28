% compareRegionScript
outdir = '~/data/occlusion/labelme/figs/regions/';

folder = db(f).annotation.folder;
bn = strtok(db(f).annotation.filename, '.');

load(fullfile(gtdir, folder, [bn '_labels']), 'lim');

load(fullfile(occdir, folder, [bn '_occlusion']), 'bndinfo_all');
occ_pb = getOcclusionPb(bndinfo_all);
lim = imresize(lim, bndinfo_all{1}.imsize, 'nearest');

im = imread(fullfile(imdir, folder, [bn '.jpg']));
im = im2double(imresize(im, bndinfo_all{1}.imsize, 'bilinear'));

out2 = fullfile(outdir, bn);

if ~exist(out2, 'file'), mkdir(out2); end
htype = 'mean';

% occave
hier = boundaries2hierarchy(mean(occ_pb, 2), bndinfo_all{1}.edges.spLR, htype);
cover_occave = getBestCovering(lim, hier.regions, bndinfo_all{1}.wseg);
    

% ucm2
load(fullfile(pb2dir, folder, [bn '_pb2_ucm']), 'ucm');
bndinfo = ucm2bndinfo(ucm);
hier = boundaries2hierarchy(bndinfo.pbnd, bndinfo.edges.spLR, htype);
cover_ucm2 = getBestCovering(lim, hier.regions, bndinfo.wseg);             

% write regions
for k = 1:max(lim(:))
    rmap = false(bndinfo_all{1}.nseg, 1); rmap(cover_occave.regions{k}) = true;
    mask = rmap(bndinfo_all{1}.wseg);
    maskim = ones(size(im)); maskim(repmat(mask, [1 1 3])) = im(repmat(mask, [1 1 3])); 
    [y, x] = find(mask); y1 = min(y); y2 = max(y); x1 = min(x); x2 = max(x);
    imwrite(maskim(y1:y2, x1:x2, :), fullfile(out2, [bn '_r' num2str(k) '_occ.jpg']), 'Quality', 95);
    
    rmap = false(bndinfo.nseg, 1); rmap(cover_ucm2.regions{k}) = true;
    mask = rmap(bndinfo.wseg);
    maskim = ones(size(im)); maskim(repmat(mask, [1 1 3])) = im(repmat(mask, [1 1 3])); 
    [y, x] = find(mask); y1 = min(y); y2 = max(y); x1 = min(x); x2 = max(x);
    imwrite(maskim(y1:y2, x1:x2, :), fullfile(out2, [bn '_r' num2str(k) '_ucm2.jpg']), 'Quality', 95);    
    
    mask = (lim==k);
    maskim = ones(size(im)); maskim(repmat(mask, [1 1 3])) = im(repmat(mask, [1 1 3])); 
    [y, x] = find(mask); y1 = min(y); y2 = max(y); x1 = min(x); x2 = max(x);
    imwrite(maskim(y1:y2, x1:x2, :), fullfile(out2, [bn '_r' num2str(k) '_gt.jpg']), 'Quality', 95);
end
imwrite(im, fullfile(out2, [bn '.jpg']), 'Quality', 95);
    
    

