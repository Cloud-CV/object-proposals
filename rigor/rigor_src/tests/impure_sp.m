% This function checks the impurity of each SP given the GT objects. If a
% SP falls on multiple GTs then it is considered impure. A pure SP has all
% its pixels inside one GT object (or completely in the background). The
% function compute the fraction of SPs in an image which are impure, plus
% also computes the average entropy of the impure SPs (a value closer to 0
% is good - a value close to 1 means that the pixels of impure SPs are
% split equally across GTs)
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function impure_sp()
data_dir = '/docs/data/images/everingham_IJCV_2010_pascalvoc/JPEGImages';
gt_dir = '/docs/data/images/everingham_IJCV_2010_pascalvoc/SegmentationObject';
voc_files = importdata(fullfile(data_dir, ...
                       '../ImageSets/Segmentation/val.txt'));

impure_frac = zeros(length(voc_files),1);
mu_entropy_impure = zeros(length(voc_files),1);

params_func = @params_StructEdges;

for idx = 1:length(voc_files)
    [imp, mu_ent] = ...
        sp_impurities(fullfile(data_dir, [voc_files{idx} '.jpg']), gt_dir, params_func);
    impure_frac(idx) = imp;
    mu_entropy_impure(idx) = mu_ent;
end

save(func2str(params_func), 'impure_frac', 'mu_entropy_impure');
end


function [impure_frac, mu_entropy_impure] = sp_impurities(img_filepath, gt_dir, params_func)
input_info.img_filepath = img_filepath;
I = imread(img_filepath);

[segm_params, filepath_params, other_params] = ...
    params_func(struct, struct, struct, struct);

seg_obj = Segmenter(I, segm_params, filepath_params, other_params, ...
                    input_info);

bndry_filepath = return_boundaries_filepath(seg_obj);
[seg_obj.bndry_data, seg_obj.timings.extra_bndry_compute_time] = ...
    Segmenter.compute_boundaries(bndry_filepath, seg_obj.I, ...
                                 seg_obj.segm_params, ...
                                 seg_obj.preload_data);

% compute superpixels
[seg_obj.sp_data, t_sp] = Segmenter.compute_superpixels(seg_obj.I, ...
                            seg_obj.bndry_data, seg_obj.segm_params);
                        
% read GT
gt_filepath = fullfile(gt_dir, [seg_obj.input_info.img_name '.png']);

ground_truth_obj_segs = imread(gt_filepath);

un = unique(ground_truth_obj_segs)';
un(un==255) = [];

sp_cnt = zeros(seg_obj.sp_data.num_spx, length(un));
for idx = 1:length(un)
    curr_gt = ground_truth_obj_segs == un(idx);
    curr_sps = seg_obj.sp_data.sp_seg(curr_gt);
    h = hist(curr_sps, 1:seg_obj.sp_data.num_spx);
    sp_cnt(:,idx) = h;
end

% compute fraction of impure sps
% 0 means dont care, 1 means that sp lies only in one GT, >1 means sp lies
% in multiple GTs
gt_sp_cnt = sum(sp_cnt ~= 0, 2);
impure_sps = gt_sp_cnt > 1;
impure_frac = nnz(impure_sps) / seg_obj.sp_data.num_spx;

% compute entropy of each impure sp
impure_sp_cnt = sp_cnt(impure_sps,:);
prob = bsxfun(@rdivide, impure_sp_cnt, sum(impure_sp_cnt,2));
log_prob = log2(prob);
log_prob(prob == 0) = 0;
entropy = -sum(prob .* log_prob, 2) ./ log2(length(un));
mu_entropy_impure = mean(entropy);
end
