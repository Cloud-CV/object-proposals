
addpath(genpath(pwd));
batch=6;

img_path='/srv/share/reranking/data/VOCBerkeley_crossval_on_val/image/';
save_loc='/srv/share/qi_rcnn_detections/sel_search/';

ids=dir([img_path '*.jpg']);
for i=(batch-1)*1000+1:batch*1000

	image_file=[img_path ids(i).name ]
	im=imread(image_file);
	boxes=selective_search_boxes(im, true);
	save_file_name=[save_loc strrep(ids(i).name,'.jpg','') '_boxes.mat' ];
	if(exist(fullfile(save_file_name),'file'))
		fprintf('exists\n');
	else
	ssave(save_file_name, 'boxes');
	end
end

exit;



