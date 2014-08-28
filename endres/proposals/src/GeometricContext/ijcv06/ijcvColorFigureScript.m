% ijcvLocationFigureScript

outdir = '/IUS/vmr20/dhoiem/data/ijcv06/results';

nb = 50; % nbins

vimages = ones(nb, nb, 3);
himages = ones(nb, nb, 5);    

for f = 1:numel(imsegs)

    segimage = imsegs(f).segimage;
    im = im2double(imread([imdir '/' imsegs(f).imname]));
    [hue, sat, val] = rgb2hsv(im);
    hue = max(ceil(hue*nb),1);
    sat = max(ceil((1-sat)*nb),1);
    
    vlab = imsegs(f).vert_labels(imsegs(f).segimage);
    hlab = imsegs(f).horz_labels(imsegs(f).segimage);        
    
    for k = 1:numel(segimage)
        if vlab(k)~=0
            vimages(sat(k), hue(k), vlab(k)) = vimages(sat(k), hue(k), vlab(k)) + 1;
        end
        if hlab(k)~=0
            himages(sat(k), hue(k), hlab(k)) = himages(sat(k), hue(k), hlab(k)) + 1;
        end            
    end   
        
    if mod(f, 50)==0
        disp(num2str(f))
    end
end

probcolor = sum(vimages, 3);
probcolor = probcolor / sum(probcolor(:));
probcolor = probcolor / max(probcolor(:));


vimages = vimages ./ repmat(sum(vimages, 3), [1 1 3]);
himages = himages ./ repmat(sum(himages, 3), [1 1 5]);

hueim = repmat([1:nb]/nb, [nb 1]);
satim = repmat(1-[1:nb]'/nb, [1 nb]);

imwrite(hsv2rgb(imresize(cat(3, hueim, satim, probcolor),1)), [outdir '/color_prob.jpg'], 'Quality', 100);
imwrite(hsv2rgb(imresize(cat(3, hueim, satim, ones(nb,nb)),1)), [outdir '/color_full.jpg'], 'Quality', 100);
for v = 1:3
    imwrite(hsv2rgb(imresize(cat(3, hueim, satim, vimages(:, :, v)),1)), ...
        [outdir '/vcol' num2str(v) '.jpg'], 'Quality', 100);
end

for h = 1:5
    imwrite(hsv2rgb(imresize(cat(3, hueim, satim, himages(:, :, h)),1)), ...
        [outdir '/hcol' num2str(h) '.jpg'], 'Quality', 100);
end

% [tmp, bestv] = max(vimages, [], 3);
% [tmp, besth] = max(himages, [], 3);
% colimseg.nseg = 7;
% colimseg.segimage = (bestv==1) + (bestv==2).*(1+besth) + 7*(bestv==3);
% for k = 1:7
%     colimseg.npixels(k) = sum(colimseg.segimage(:)==k);
% end
% lim = APPgetLabeledImage(ones(200,200, 3), colimseg, ...
%     {'000', '090', '090', '090', '090', '090', 'sky'}, ones(7, 1), ...
%     {'---', '045', '090', '135', 'por', 'sol', '---'}, ones(7, 1));
% imwrite(lim, [outdir '/labeledcol.jpg'], 'Quality', 100);
% lim2 = (lim>0).*vimages(:, :, [2 1 3]);
% imwrite(lim2, [outdir '/labeledcol.jpg'], 'Quality', 100);
