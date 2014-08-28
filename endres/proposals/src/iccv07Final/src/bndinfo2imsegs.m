function imsegs2 = bndinfo2imsegs(bndinfo, imsegs1)

tmpseg.segimage = bndinfo.wseg;
if isfield(bndinfo, 'imname')
    tmpseg.imname = bndinfo.imname;
end

stats = regionprops(bndinfo.wseg, 'Area');
tmpseg.npixels = vertcat(stats.Area);
tmpseg.nseg = numel(tmpseg.npixels);
tmpseg.imsize = bndinfo.imsize(1:2);

if exist('imsegs1', 'var') && isfield(imsegs1, 'labels')
    imsegs2 = APPtransferLabels(imsegs1, tmpseg);
else
    imsegs2 = tmpseg;
end

imsegs2 = orderfields(imsegs2);
