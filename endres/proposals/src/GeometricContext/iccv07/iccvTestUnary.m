function [vacc2, hacc2, vcm2, hcm2, cimages2] = iccvTestUnary(w)
% iccvTrainUnary

outdir = '/usr1/projects/GeometricContext/data/iccv07/test/unary/';

%classifiers = load('/usr1/projects/GeometricContext/data/ijcv06/ijcvClassifier.mat');
tmp = load('/usr1/projects/GeometricContext/data/ijcv06/multisegResults2.mat');
pg = tmp.pg2;

load('/usr1/projects/GeometricContext/data/allimsegs2.mat');
load('/usr1/projects/GeometricContext/data/rand_indices.mat');

imdir = '/usr1/projects/GeometricContext/images/all_images/';
fn = {imsegs(cv_images).imname};
for f = 1:numel(fn)
    fn{f} = [imdir fn{f}];
end


for f = 1:numel(fn)       
    
    disp(num2str(f))
    
    f2 = cv_images(f); 
    
    savename = [outdir '/' strtok(imsegs(f2).imname, '.') '.c.mat'];
    
    if ~exist(savename, 'file')
    
        im = im2double(imread(fn{f}));
               
        % get geometry confidence images

        % pg{f} is loaded from file
        %pg{f} = ijcvTestImage(im, imsegs(f2), classifiers);
        [cimages, cnames] = pg2confidenceImages(imsegs(f2), pg(f));          
        %writeConfidenceImages(imsegs(f2), pg(f), outdir);    
    
        cim_geom_3 = cimages{1}(:, :, [1 8 7]);
        cim_geom_7 = cimages{1}(:, :, 1:7);
    
        % get color confidence images
        cim_color_7 = unaryColor(im, cim_geom_7); 
        cim_color_3 = unaryColor(im, cim_geom_3);          
    
        % get texture confidence images
        cim_texture_7 = unaryTexture(im, cim_geom_7);
        cim_texture_3 = unaryTexture(im, cim_geom_3);
            
        save(savename, 'cnames', ...
            'cim_geom_3', 'cim_geom_7', 'cim_color_3', 'cim_color_7', ...
            'cim_texture_3', 'cim_texture_7');  
    
        figure(1), imagesc(im), axis image
        figure(2), imagesc(cim_geom_3(:, :, [2 1 3])), axis image
        figure(3), imagesc(cim_color_3(:, :, [2 1 3])), axis image
        figure(4), imagesc(cim_texture_3(:, :, [2 1 3])), axis image    
        drawnow;      
    
    end
    
    haspassed = 0;
    
    while ~haspassed
    
        try

            tmp = load(savename);

            [imh, imw, nc] = size(tmp.cim_geom_3);
            logp{1} = log(reshape(tmp.cim_geom_3, [imh*imw nc]));
            logp{2} = log(reshape(tmp.cim_color_3, [imh*imw nc]));
            logp{3} = log(reshape(tmp.cim_texture_3, [imh*imw nc]));

            cimages2{f} = computeConfidences(w, logp);
            cimages2{f} = single(reshape(cimages2{f}, [imh imw nc]));


            if size(cimages2{f}, 3)==3
                tmp = tmp.cim_geom_7;
                tmp(:, :, 1) = cimages2{f}(:, :, 1);
                tmp(:, :, 7) = cimages2{f}(:, :, 3);
                tmp(:, :, 2:6) = tmp(:, :, 2:6) ./ ...
                    repmat(sum(tmp(:, :, 2:6), 3), [1  1 5]) ...
                    .* repmat(cimages2{f}(:, :, 2), [1 1 5]);
                cimages2{f} = single(tmp);
            end

            tmpim = cat(3, cimages2{f}(:, :, 1), sum(cimages2{f}(:, :, 2:6), 3), ...
                cimages2{f}(:, :, 7));
            figure(5), imagesc(tmpim(:, :, [2 1 3])), axis image
            drawnow;

            haspassed = 1;
        catch
            disp('failed')
            keyboard
        end
    end
    
end

[vacc2, hacc2, vcm2, hcm2] = mcmcProcessResult_pixels(imsegs(cv_images), cimages2);

save([outdir 'unaryResults3.mat'], 'w', 'vacc2', 'hacc2', 'vcm2', 'hcm2');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pg = computeConfidences(w, logp)

pg = zeros(size(logp{1}));
for k = 1:numel(logp)
    pg = pg  + w(k)*logp{k};
end
pg = exp(pg)+0.0000001;
pg = pg ./ repmat(sum(pg, 2), [1 size(pg, 2)]);



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

