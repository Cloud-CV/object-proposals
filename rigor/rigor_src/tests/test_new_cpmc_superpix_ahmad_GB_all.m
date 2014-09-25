% Need to specify this_fold and num_folds!
setenv('OMP_NUM_THREADS','6');
exp_dir = '/export/scratch/ahumayun/data/images/everingham_IJCV_2010_pascalvoc/';
img_names = textread('./Lefts_Gb.txt','%s');
%img_names = textread([exp_dir '/ImageSets/Segmentation/val.txt'],'%s');
        mx = length(img_names);
        each = floor(mx / num_folds) + 1;
        lb = 1 + (this_fold - 1 ) * each;
        ub = this_fold * each;
        if ub > length(img_names)
            ub = length(img_names);
        end
for i=lb:ub
for k=1:10
    file_params.extern_src_dir = '/export/scratch/fuxin/git/extern/';
    file_params.data_save_dirpath = ['/export/scratch/fuxin/RunAhmadVOC/GB_' num2str(k) '/'];
    segm_params.boundaries_method = 'Gb';
    segm_params.pmc_maxflow_method = 'kolmogorov';
    segm_params.graph_methods = {'UniformGraphFuxin','ColorGraphFuxin'};
    segm_params.graph_sub_methods = {{'internal','external','external2'},{'internal','external','external2'}};
    segm_params.graph_sub_methods_seeds_idx = {[1,1,1],[2,2,2]};
    segm_params.graph_sol_upper_bp = [20,300];
 %   segm_params.graph_seed_gen_method = {'sp_seed_sampling', 'sp_clr_seeds'};
%    segm_params.graph_seed_params = {{64, 4, 'trained_models/train_trees.mat',4},{[8 8], [15, 15]}};
    segm_params.graph_seed_params = { {[k k], [40, 40]},     {[k k], [15, 15]}    };
    segm_params.graph_pairwise_sigma = {3.5,3.5};
    other_params.force_recompute = true;

    img_masks = rigor_obj_segments([exp_dir '/JPEGImages/' img_names{i} '.jpg'],'filepath_params',file_params,'segm_params',segm_params,'other_params',other_params);
%    [Q,collated_scores] = SvmSegm_segment_quality(img_names{i}, [exp_dir 'SegmentationObject/'], img_masks, 'overlap');
%    the_quality_dir = ['/export/scratch/fuxin/RunAhmadVOC/Gb_' num2str(k) '/SegmentEval/overlap/'];
%    if ~exist(the_quality_dir,'dir')
%        mkdir(the_quality_dir);
%    end
%    save([the_quality_dir img_names{i} '.mat'],'Q','collated_scores')
end
end
