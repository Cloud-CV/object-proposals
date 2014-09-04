
addpath(genpath(pwd));
clsNum=102;
type='neg';
sprintf('/home/gneelima/ILSVRC2013_devkit/data/det_lists/train_%s_%s.txt',type,num2str(clsNum))
ids = textread(sprintf('/home/gneelima/ILSVRC2013_devkit/data/det_lists/train_%s_%s.txt',type,num2str(clsNum)),'%s');


img_path='/home/gneelima/imagenetImages/images/ILSVRC2013_DETextra_train/ILSVRC2013_train/';
save_loc='/home/gneelima/Selective_search_imagenet/ILSVRC2013_DETextra_train/';

for i=1:length(ids)
image_file=[img_path ids{i} '.JPEG' ]
im=imread(image_file);
boxes=selective_search_boxes(im, true);
save_file_name=[save_loc strrep(ids{i},'.JPEG','') '_boxes.mat' ]
if(exist(fullfile(save_file_name),'file'))
fprintf('exists\n');
else
ssave(save_file_name, 'boxes');
end
end

exit;



