% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function prep_deploy()
    % to be run to set the directory up for deployment
    u = userpath;
    matlab_path = u(1:end-1);

    code_root_dir = fullfile(fileparts(which(mfilename)), '..');
    extern_src_rel_dst = 'extern_src';
    algos_dir_dst = fullfile(code_root_dir, extern_src_rel_dst);
    utils_dir_dst = fullfile(code_root_dir, 'utils');
    algos_dir_src = fullfile(code_root_dir, '..', 'extern_src');

    % delete old directories & files (as a result of previous run of this script)
    if_exist_del(fullfile(code_root_dir, 'data'));
    if_exist_del(fullfile(algos_dir_dst, 'fuxin_lib_src'));
    if_exist_del(fullfile(algos_dir_dst, 'segmentation'));
    if_exist_del(fullfile(algos_dir_dst, 'stein_boundaryprocessing'));
    if_exist_del(fullfile(algos_dir_dst, 'toolboxes'));
    if_exist_del(fullfile(algos_dir_dst, 'utils'));
    if_exist_del(fullfile(utils_dir_dst, 'drawFigFrames.m'));
    if_exist_del(fullfile(utils_dir_dst, 'timerTicks.m'));
    if_exist_del(fullfile(utils_dir_dst, 'compute_error_metric.m'));
    if_exist_del(fullfile(utils_dir_dst, 'duplicateElems.m'));

    % copy files needed from matlab user directory
    copyfile(fullfile(matlab_path, 'drawFigFrames.m'), utils_dir_dst);
    copyfile(fullfile(matlab_path, 'timerTicks.m'), utils_dir_dst);
    copyfile(fullfile(matlab_path, 'duplicateElems.m'), utils_dir_dst);

    % copy necessary files from fuxin library
    mkdir(fullfile(algos_dir_dst, 'fuxin_lib_src'));
    copyfile(fullfile(code_root_dir, '..', 'fuxin_lib_src', 'boosting'), fullfile(algos_dir_dst, 'fuxin_lib_src', 'boosting'));
    copyfile(fullfile(code_root_dir, '..', 'fuxin_lib_src', 'myqueue_1.1'), fullfile(algos_dir_dst, 'fuxin_lib_src', 'myqueue_1.1'));
    copyfile(fullfile(code_root_dir, '..', 'fuxin_lib_src', '@classregtree_fuxin'), fullfile(algos_dir_dst, 'fuxin_lib_src', '@classregtree_fuxin'));

    % copy stein boundary processing
    copyfile(fullfile(algos_dir_src, 'segmentation', 'stein_boundaryprocessing'), fullfile(algos_dir_dst, 'stein_boundaryprocessing'));
    
    copyfile(fullfile(algos_dir_src, 'compute_error_metric.m'), utils_dir_dst);
end

function if_exist_del(delpath)
    if exist(delpath, 'dir')
        rmdir(delpath, 's');
    elseif exist(delpath, 'file')
        delete(delpath);
    end
end