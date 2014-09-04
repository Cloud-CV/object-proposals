
addpath(genpath(pwd));
clsNum=22;
type='pos';
sprintf('/home/gneelima/ILSVRC2013_devkit/data/det_lists/train_%s_%s.txt',type,num2str(clsNum))
ids = textread(sprintf('/home/gneelima/ILSVRC2013_devkit/data/det_lists/train_%s_%s.txt',type,num2str(clsNum)),'%s');


img_path='/home/gneelima/imagenetImages/images/';
save_loc='/home/gneelima/Selective_search_imagenet/';

for i=1:length(ids)
image_folder=strtok(ids{i},'_');
image_file=[img_path image_folder '/' ids{i} '.JPEG' ]
im=imread(image_file);
boxes=selective_search_boxes(im, true);
save_file_name=[save_loc image_folder '/' strrep(ids{i},'.JPEG','') '_boxes.mat' ];
if(exist(fullfile(save_file_name),'file'))
fprintf('exists\n');
else
ssave(save_file_name, 'boxes');
end
end

exit;



