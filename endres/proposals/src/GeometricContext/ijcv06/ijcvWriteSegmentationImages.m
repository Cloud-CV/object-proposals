function ijcvWriteSegmentationImages(imdir, imsegs, smaps, outdir)

for f = 1:numel(imsegs)
    im = im2double(imread([imdir '/' imsegs(f).imname]));
    size(im)
    for k = 1:size(smaps{f}, 2)
        sim = displaySegments(smaps{f}(:, k), imsegs(f).segimage, 0.5+0.5*rgb2gray(im), 0);
        snum = num2str(100 + k);
        snum = snum(2:end);
        imwrite(sim, [outdir '/' strtok(imsegs(f).imname, '.') '_s' snum '.jpg'], 'Quality', 90);
    end
    sim = displaySegments([1:imsegs(f).nseg]', imsegs(f).segimage, 0.5+0.5*rgb2gray(im), 0);
    imwrite(sim, [outdir '/' strtok(imsegs(f).imname, '.') '_sp.jpg'], 'Quality', 90);
end