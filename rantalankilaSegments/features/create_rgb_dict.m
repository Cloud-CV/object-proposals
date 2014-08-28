% Script to create rgb dictionary for use with feature_color.m

images = textread(sprintf(VOCopts.seg.imgsetpath,'train'),'%s');

I_all = [];
s = 8;

tic
%for i = 1:length(images)
for i = 1:100
    I = imread(lp(0,sprintf(VOCopts.imgpath, char(images(i)))) );
    %I = uint8(rgb_to_opp_nocut(I));
    I = I(1:s:end, 1:s:end,:); % subsampling
    I_all = [I_all; reshape(I, size(I,1)*size(I,2), 3)];
end
toc

tic
k = 50;
[color_dict, ~] = vl_ikmeans(I_all', k);
toc

return

% Visualize color clustering
Ic = imread(lp(0,sprintf(VOCopts.imgpath, char(images(5)))) );
[s1,s2,~] = size(Ic);
color_dict = int32(color_dict); 
words = vl_ikmeanspush(reshape(Ic, size(Ic,1)*size(Ic,2), 3)', color_dict);

Ic = color_dict(:,words')';
Ic = uint8(reshape(Ic, s1, s2, 3));
imshow(Ic);


% save('dicts/rgb_dict_k50', 'color_dict')

