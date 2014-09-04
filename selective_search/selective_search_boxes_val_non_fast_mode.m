function selective_search_boxes_val_non_fast_mode(batch)


addpath(genpath(pwd));
ids = textread('/home/gneelima/ILSVRC2013_devkit/data/det_lists/val.txt','%s%*[^\n]');
length(ids)
img_path='/home/gneelima/imagenetImages/images/val/';
save_loc='/home/gneelima/Selective_search_imagenet/val/';


for i=(batch-1)*2000+1:batch*2000
image_file=[img_path ids{i} '.JPEG' ]
im=imread(image_file);
save_file_name=[save_loc strrep(ids{i},'.JPEG','') '_boxes.mat' ];
if(exist(fullfile(save_file_name),'file'))
fprintf('exists\n');
else
length(size(im))
if(length(size(im))~=3)
size(im)
im=cat(3,im,im,im);
end
size(im)
boxes=selective_search_boxes(im, false);
ssave(save_file_name, 'boxes');
end
end
exit
