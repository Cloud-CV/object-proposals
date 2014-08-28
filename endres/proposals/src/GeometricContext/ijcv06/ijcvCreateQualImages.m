% ijcvCreateQualImagesScript

imdir = '../images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06/results/qualf';

tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/featureResultsSingle2.mat');
pg = tmp.pg;

fn = {'dirt02', 'streets04', 'scenery14', 'outdoor80'};

for f = 1:numel(fn)
    fnind(f) = find(strcmp({imsegs(cv_images).imname}, [fn{f} '.jpg']));
end

suffix = {'_l', '_c', '_t', '_p'};

for k = 1:4

for f = fnind
    cf = cv_images(f);
    im = im2double(imread([imdir '/' imsegs(cf).imname]));
    disp([num2str(f) ': ' imsegs(cf).imname])
    [vc, hc] = splitpg(pg{k}{f});      
    
    lim = APPgetLabeledImage2(im, imsegs(cf), vc, hc);
    %figure(1), imshow(lim)
    %system(['cp ' imdir '/' imsegs(f).imname ' ' outdir '/' imsegs(f).imname]);
    imwrite(lim, [outdir '/' strtok(imsegs(cf).imname, '.') suffix{k} '_l.jpg'], 'Quality', 90);        
end
end