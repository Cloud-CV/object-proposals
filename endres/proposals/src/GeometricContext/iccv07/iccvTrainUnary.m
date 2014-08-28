function w = iccvTrainUnary
% iccvTrainUnary

outdir = '/usr1/projects/GeometricContext/data/iccv07/train/unary/';

classifiers = load('/usr1/projects/GeometricContext/data/ijcv06/ijcvClassifier.mat');
load('/usr1/projects/GeometricContext/data/allimsegs2.mat');
load('/usr1/projects/GeometricContext/data/rand_indices.mat');

imdir = '/usr1/projects/GeometricContext/images/all_images/';
fn = {imsegs(cluster_images).imname};
for f = 1:numel(fn)
    fn{f} = [imdir fn{f}];
end


for f = 1:numel(fn)       
    
    disp(num2str(f))
    
    f2 = cluster_images(f); 
    
    savename = [outdir '/' strtok(imsegs(f2).imname, '.') '.c.mat'];
    
    if ~exist(savename, 'file')
    
        im = im2double(imread(fn{f}));
               
        % get geometry confidence images
        pg{f} = ijcvTestImage(im, imsegs(f2), classifiers);
        [cimages, cnames] = pg2confidenceImages(imsegs(f2), pg(f));          
        writeConfidenceImages(imsegs(f2), pg(f), outdir);    
    
        cim_geom_3 = cimages{1}(:, :, [1 8 7]);
        cim_geom_7 = cimages{1}(:, :, 1:7);
    
        % get color confidence images
        cim_color_7 = unaryColor(im, cim_geom_7); 
        cim_color_3 = unaryColor(im, cim_geom_3);          
    
        % get texture confidence images
        cim_texture_7 = unaryTexture(im, cim_geom_7);
        cim_texture_3 = unaryTexture(im, cim_geom_3);
            
        save([outdir '/' strtok(imsegs(f2).imname, '.') '.c.mat'], 'cnames', ...
            'cim_geom_3', 'cim_geom_7', 'cim_color_3', 'cim_color_7', ...
            'cim_texture_3', 'cim_texture_7');  
    
        figure(1), imagesc(im), axis image
        figure(2), imagesc(cim_geom_3(:, :, [2 1 3])), axis image
        figure(3), imagesc(cim_color_3(:, :, [2 1 3])), axis image
        figurenpix = 0;(4), imagesc(cim_texture_3(:, :, [2 1 3])), axis image    
        drawnow;      
    
    end
    
    tmp = load(savename);
    
    cim{f} = tmp.cim_geom_7;
    [imh, imw, nc] = size(tmp.cim_geom_7);
    cim{f} = reshape(cim{f}, [imh*imw nc]);
    cim2{f} = reshape(tmp.cim_color_7, [imh*imw nc]);
    cim3{f} = reshape(tmp.cim_texture_7, [imh*imw nc]);
    lab{f} = imsegs(f2).labels(imsegs(f2).segimage);
    
    ind = lab{f}(:) > 0;
    
    if sum(ind) > 250000
       rp = randperm(imh*imw);
       ind(rp(1:imh*imw-250000)) = 0;
    end
            
    lab{f} = uint8(lab{f}(ind));
    cim{f} = single(cim{f}(ind, :));
    cim2{f} = single(cim2{f}(ind, :));
    cim3{f} = single(cim3{f}(ind, :));
     
    clear tmp
end

lab = cat(1, lab{:});
lab = uint32((1:numel(lab))' + numel(lab)*(double(lab)-1));

logp{1} = log(cat(1, cim{:}));
clear cim;
logp{2} = log(cat(1, cim2{:}));
clear cim2;
logp{3} = log(cat(1, cim3{:}));
clear cim3;

for k = 1:numel(logp)
    logp{k} = double(logp{k});
end

options = optimset('Display', 'iter');
[w, val] = fminunc(@(w) dataLogLikelihood(w, logp, lab), [1 0 0], options);
disp(num2str(w));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dll = dataLogLikelihood(w, logp, lab)

p = zeros(size(logp{1}));
for k = 1:numel(logp)
    p = p  + w(k)*logp{k};
end
dll = exp(p)+0.0001;

clear p;

dll = dll(lab) ./ sum(dll, 2);
disp(num2str(w))
disp(num2str(mean(dll)))

dll = -mean(log(dll));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pim = unaryColor(im, cim)

nclasses = size(cim, 3);

[imh, imw, nbands] = size(im);

% discretize image in hsv space
[h, s, v] = rgb2hsv(im);
h = floor(h*9.99); % h ranges from 0 to 9
s = (s > 0.05) + (s > 0.15) + (s > 0.35) + (s > 0.5); % s ranges from 0 to 4
v = floor(v*4.99); % v ranges from 0 to 4

imd = h + s*10 + v*50 + 1;

%figure(2), imagesc(label2rgb(imd, 'jet', 'c', 'shuffle')), axis image
%drawnow;

imd = reshape(imd, [imh*imw 1]);



nb = max(imd(:));

cim = reshape(cim, [imh*imw nclasses]);

sumc = sum(cim, 1);

prob = zeros(imh*imw, nclasses); 
for b = 1:nb
    ind = (imd==b);
    p = sum(cim(ind, :), 1)+0.001;    % laplacian prior of 1
    p = p ./ sumc;
    p = p / sum(p);
    prob(ind, :) = repmat(p, [sum(ind) 1]);
end

pim = reshape(prob, [imh imw nclasses]);
%imwrite(pim(:, :, [2 1 3]), './tmp/pim.jpg');
%figure(3), imagesc(pim(:, :, [2 1 3])), axis image;
%drawnow;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pim = unaryTexture(im, cim)


nclasses = size(cim, 3);

[imh, imw, nbands] = size(im);

filtext = makeLMfilters;
ntext = size(filtext, 3);

grayim = rgb2gray(im);

imtext = zeros(imh*imw, ntext);
for f = 1:ntext
    imtext(:, f) = ...
        reshape(abs(imfilter(im2single(grayim), filtext(:, :, f), 'same')), [imh*imw 1]);    
end

%imd = kmeans(imtext, 50, 'MaxIter', 15);
if imh*imw > 10000
    rp = randperm(imh*imw);
    rp = rp(1:10000);
    [tmp, means] = kmeansML(50, imtext(rp, :)','maxiter',30,'verbose',0);
    z = distSqr(imtext',means);
    [tmp,imd] = min(z,[],2);    
else
    imd = kmeansML(50, imtext','maxiter',30,'verbose',0);
end

%imd = computeTextons(imtext, 50);


%figure(3), imagesc(label2rgb(imd, 'jet', 'c', 'shuffle')), axis image
%drawnow;

imd = reshape(imd, [imh*imw 1]);

nb = max(imd(:));

cim = reshape(cim, [imh*imw nclasses]);

sumc = sum(cim, 1);

prob = zeros(imh*imw, nclasses); 
for b = 1:nb
    ind = (imd==b);
    p = sum(cim(ind, :), 1)+1;    % laplacian prior of 1
    p = p ./ sumc;
    p = p / sum(p);
    prob(ind, :) = repmat(p, [sum(ind) 1]);
end

pim = reshape(prob, [imh imw nclasses]);
%imwrite(pim(:, :, [2 1 3]), './tmp/pim.jpg');
%figure(3), imagesc(pim(:, :, [2 1 3])), axis image;
%drawnow;

