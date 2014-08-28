% ijcvLocationFigureScript

outdir = '/IUS/vmr20/dhoiem/data/ijcv06/results';

vimages = zeros(200, 200, 3);
himages = zeros(200, 200, 5);    

for f = 1:numel(imsegs)

    tmpseg = imresize(imsegs(f).segimage, [200 200]);    
    
    for v = 1:3
        lab = (imsegs(f).vert_labels==v);
        vimages(:, :, v) = vimages(:, :, v) + lab(tmpseg);
    end
        
    for h = 1:5
        lab = (imsegs(f).horz_labels==h);
        himages(:, :, h) = himages(:, :, h) + lab(tmpseg);
    end    
        
    if mod(f, 50)==0
        disp(f)
    end
end
vimages = vimages ./ repmat(sum(vimages, 3), [1 1 3]);
himages = himages ./ repmat(sum(himages, 3), [1 1 5]);

[tmp, bestv] = max(vimages, [], 3);
[tmp, besth] = max(himages, [], 3);

locimseg.nseg = 7;
locimseg.segimage = (bestv==1) + (bestv==2).*(1+besth) + 7*(bestv==3);
for k = 1:7
    locimseg.npixels(k) = sum(locimseg.segimage(:)==k);
end
lim = APPgetLabeledImage(ones(200,200, 3), locimseg, ...
    {'000', '090', '090', '090', '090', '090', 'sky'}, ones(7, 1), ...
    {'---', '045', '090', '135', 'por', 'sol', '---'}, ones(7, 1));

imwrite(vimages(:, :, [2 1 3]), [outdir '/mainclassloc.jpg'], 'Quality', 100);
for v = 1:3
    imwrite(vimages(:, :, v), [outdir '/vloc' num2str(v) '.jpg'], 'Quality', 100);
end

for h = 1:5
    imwrite(himages(:, :, h), [outdir '/hloc' num2str(h) '.jpg'], 'Quality', 100);
end

imwrite(lim, [outdir '/labeledloc.jpg'], 'Quality', 100);

lim2 = (lim>0).*vimages(:, :, [2 1 3]);
imwrite(lim2, [outdir '/labeledloc2.jpg'], 'Quality', 100);