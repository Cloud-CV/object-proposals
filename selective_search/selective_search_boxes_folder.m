
function selective_search_boxes_folder(folder)
addpath(genpath(pwd));


img_path=['/home/gneelima/imagenetImages/images/' folder] 
save_loc=['/home/gneelima/Selective_search_imagenet/' folder]

ids=dir([img_path '/*.JPEG']);

size(ids)
for i=1:length(ids)
save_file_name=[save_loc '/' strrep(ids(i).name,'.JPEG','')  '_boxes.mat' ]
if(exist(fullfile(save_file_name),'file'))
fprintf('exists\n');
else
fprintf('calculating..\n');
im=imread([img_path '/' ids(i).name]);
boxes=selective_search_boxes(im, true);
ssave(save_file_name, 'boxes');
end
end

exit;

