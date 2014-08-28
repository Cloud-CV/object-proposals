function [features, labels] = ijcvPixelFeatures(imdir, imsegs, pixperim)
%      01 - 03: rgb values
%      04 - 06: hsv conversion
%      07 - 21: mean texture response
%      22     : max texture response
%      23 - 24: x, y positions

features = cell(numel(imsegs), 1);
labels = cell(numel(imsegs), 1);

filtext = makeLMfilters;
ntext = size(filtext, 3);

for f = 1:numel(imsegs)
    
    disp(['pixel features: ' num2str(f)])
    
    im = im2double(imread([imdir '/' imsegs(f).imname]));
    grayim = rgb2gray(im);

    [imh imw] = size(grayim);
    
    % texture
    imtext = zeros([imh imw ntext]);
    for k = 1:ntext
        imtext(:, :, k) = abs(imfilter(im2single(grayim), filtext(:, :, k), 'same'));    
    end
    [tmp, textmax] = max(imtext, [], 3);
        
    features{f} = zeros(pixperim, ntext+9);
    labels{f} = zeros(pixperim, 1);    
       
    rp = randperm(imh*imw);
    rp = rp(1:pixperim);
    
    for i = 1:pixperim
        yi = mod(rp(i)-1, imh)+1;
        xi = floor((rp(i)-1)/imh)+1;

        % color
        features{f}(i, 1:3) = reshape(im(yi, xi, :), [1 3]);
        features{f}(i, 4:6) = rgb2hsv(features{f}(i, 1:3));
        
        % texture
        features{f}(i, (6+1):(6+ntext)) = reshape(imtext(yi, xi, :), [1 ntext]);
        features{f}(i, 6+ntext+1) = textmax(yi, xi);
        
        % position
        features{f}(i, 6+ntext+(2:3)) = [(xi-1)/(imw-1) (yi-1)/(imh-1)];
        
        % label
        labels{f}(i) = imsegs(f).labels(imsegs(f).segimage(rp(i)));
    end
end
        
        
   