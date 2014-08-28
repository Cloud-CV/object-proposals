% Script to create SIFT dictionary for use with feature_dsift.m

images = textread(sprintf(VOCopts.seg.imgsetpath,'train'),'%s');

I_all = [];
binSize = 8; % default 8
magnif = 3; % default 3
s = 20; % subsampling

tic
%for i = 1:length(images)
for i = 1:100
    I = imread(lp(0,sprintf(VOCopts.imgpath, char(images(i)))) );
    I = single(rgb2gray2(I)); 
    I = vl_imsmooth(I, sqrt((binSize/magnif)^2 - .25)) ;
    [~, dsift_feat] = vl_dsift(I, 'size', binSize, 'step', s); % size 8
    I_all = [I_all, dsift_feat];
end
toc

tic
k = 10;
[dsift_dict, ~] = vl_ikmeans(I_all, k);
toc

return

% Visualize dsift clustering
Ic = single(rgb2gray2(imread(lp(0,sprintf(VOCopts.imgpath, char(images(90)))))));
Ic = vl_imsmooth(Ic, sqrt((binSize/magnif)^2 - .25));
[~, dsift_feat1] = vl_dsift(Ic, 'size', binSize, 'step', 1);
words_mid = vl_ikmeanspush(dsift_feat1, dsift_dict);
[s1, s2] = size(Ic);
Iq = reshape(words_mid, s1-binSize*magnif, s2-binSize*magnif);
imshow(uint8(Ic));
figure
Iq = uint8(Iq*255/k);
imshow(Iq);


% save('dicts/dsift_new', 'dsift_dict', 'binSize', 'magnif')

