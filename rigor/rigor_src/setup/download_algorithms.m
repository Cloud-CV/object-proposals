function download_algorithms(simulate_no_download)
% Downloads and compiles/preps different external codes needed for RIGOR
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

clc

% if you don't want to download the files (for testing this script)
if ~exist('simulate_no_download', 'var')
    simulate_no_download = false;
end
no_download_dir = 'pre_downloaded';

fprintf(2, '---------------------------------------------------------------------------\n                              Download Notice                              \n---------------------------------------------------------------------------\nBy running this script, you accept all licensing agreements accompanied\nwith the 3rd party softwares that will now be downloaded and used later in\nour scripts.\n\nPress ''y'' to accept (any other key to stop the script): ');
user_inp = input('','s');
if isempty(user_inp) || ~strncmpi(user_inp(1), 'y', 1)
    return;
end

% destination algorithms directory
curr_dir = pwd;
code_root_dir = fullfile(fileparts(which(mfilename)), '..');
extern_src_rel = 'extern_src';
algos_dir = fullfile(code_root_dir, extern_src_rel);
dont_delete = {'DataHash', 'extra_gb_code', 'para_pseudoflow', 'fuxin_lib_src', 'stein_boundaryprocessing'};
if exist(algos_dir,'dir')
    % only delete the dir/files not in dont_delete
    d = dir(algos_dir);
    for idx = 1:length(d)
        if strcmp(d(idx).name,'.') || strcmp(d(idx).name,'..')
            continue;
        end
        if ~any(strcmp(d(idx).name, dont_delete))
            if d(idx).isdir
                rmdir(fullfile(algos_dir,d(idx).name), 's');
            else
                delete(fullfile(algos_dir,d(idx).name));
            end
        end
    end
else
    mkdir(algos_dir);
end

% create temp download directory
if ~simulate_no_download
    temp_dir = fullfile(code_root_dir, sprintf('temp%d', randi(1e8)));
    mkdir(temp_dir);
else
    temp_dir = no_download_dir;
end

try
    % Point Fuxin library to the right directory
    fuxin_lib_rel = fullfile(extern_src_rel, 'fuxin_lib_src');
    replaceInTextFile(fullfile(code_root_dir, 'internal_params.m'), '''/home/ahumayun/videovolumes/fuxin_lib_src''', ['fullfile(fp.code_root_dir, ''', fuxin_lib_rel, ''')'], true);
    classregtree_dir = fullfile(fuxin_lib_rel, '@classregtree_fuxin', 'private');
    fprintf(1, 'mex''ing fuxin library code\n');
    eval(sprintf('mex -O %s/regtreeEval.cpp -output %s/regtreeEval', classregtree_dir, classregtree_dir));
    eval(sprintf('mex -O %s/regtree_findbestsplit.cpp -output %s/regtree_findbestsplit', classregtree_dir, classregtree_dir));
    fprintf(1, 'Done mex''ing\n');
    
    
    % move stein boundary processing code to the segmentation folder
    mkdir(fullfile(algos_dir, 'segmentation'));
    copyfile(fullfile(algos_dir, 'stein_boundaryprocessing'), fullfile(algos_dir, 'segmentation', 'stein_boundaryprocessing'));
    
    
    % download Leordeanu''s GB code
    success = download_code('http://109.101.234.42/documente/code/doc_8.zip', ...
        fullfile(temp_dir, 'doc_8.zip'), 'Leordeanu''s GB flow code', simulate_no_download);
        
    if success
        mkdir(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb'));
        unzip(fullfile(temp_dir, 'doc_8.zip'), fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb'));
        movefile(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb', 'Gb_Code_Oct2012', '*'), fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb'));
        rmdir(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb', 'Gb_Code_Oct2012'), 's');
        replaceInTextFile(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb', 'Gb_data_lambda.m'), 'gb\(f\) = T/2 \+ sqrt\(\(T \.\^ 2 \) /4 \- D\);', 'gb(f) = T(f)/2 + sqrt((T(f) .^ 2 ) /4 - D(f));');
        replaceInTextFile(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb', 'Gb_data_lambda.m'), 'or_C\(f, 1\) = -Ms\(:, 2\);', 'or_C(f, 1) = -Ms(f, 2);');
        replaceInTextFile(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb', 'Gb_data_lambda.m'), 'or_C\(f, 2\) = gb\(:\) - Ms\(:, 1\);', 'or_C(f, 2) = gb(f) - Ms(f, 1);');
        adjustAttributes(fullfile(algos_dir, 'segmentation', 'boundaries--leordeanu_ECCV_2012_gb'));
    end
    
    % download Joseph Lim's SketchTokens code
    success = download_code('https://github.com/joelimlimit/SketchTokens/archive/master.zip', ...
        fullfile(temp_dir, 'master.zip'), 'Joseph Lim''s SketchTokens code', simulate_no_download);
    success = success & download_code('http://people.csail.mit.edu/lim/lzd_cvpr2013/st_data.tgz', ...
        fullfile(temp_dir, 'st_data.tgz'), 'Joseph Lim''s SketchTokens data', simulate_no_download);
    
    if success
        mkdir(fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens'));
        unzip(fullfile(temp_dir, 'master.zip'), fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens'));
        untar(fullfile(temp_dir, 'st_data.tgz'), fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens'));
        rmdir(fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens', 'SketchTokens-master', 'models'), 's');
        movefile(fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens', 'models'), fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens', 'SketchTokens-master'));
        movefile(fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens', 'SketchTokens-master', '*'), fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens'));
        rmdir(fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens', 'SketchTokens-master'), 's');
        cd(fullfile(algos_dir, 'segmentation', 'boundaries--lim_CVPR_2013_sketchtokens'));
        mex stDetectMex.cpp 'OPTIMFLAGS="$OPTIMFLAGS' '/openmp"'
        fprintf(1, 'Done mex''ing\n');
        cd(curr_dir);
    end
    
    
    % download Piotr's toolbox code
    success = download_code('http://vision.ucsd.edu/~pdollar/toolbox/piotr_toolbox.zip', ...
        fullfile(temp_dir, 'piotr_toolbox.zip'), 'Piotr''s toolbox code', simulate_no_download);
    
    if success
        mkdir(fullfile(algos_dir, 'toolboxes', 'piotr_toolbox'));
        unzip(fullfile(temp_dir, 'piotr_toolbox.zip'), fullfile(algos_dir, 'toolboxes', 'piotr_toolbox'));
        movefile(fullfile(algos_dir, 'toolboxes', 'piotr_toolbox', 'toolbox', '*'), fullfile(algos_dir, 'toolboxes', 'piotr_toolbox'));
        rmdir(fullfile(algos_dir, 'toolboxes', 'piotr_toolbox', 'toolbox'), 's');
        % do not compile for linux - there is some problem when running
        % struct edges with compiled code (rather than with the compiled
        % code that comes with the library)
        if ~isunix
            cd(fullfile(algos_dir, 'toolboxes', 'piotr_toolbox', 'external'));
            toolboxCompile;
            fprintf(1, 'Done mex''ing\n');
            cd(curr_dir);
        end
    end
    
    
    % download Piotr's Struct Edges code
    success = download_code('http://ftp.research.microsoft.com/downloads/389109f6-b4e8-404c-84bf-239f7cbf4e3d/releaseV3.zip', ...
        fullfile(temp_dir, 'release.zip'), 'Piotr''s Struct Edges code', simulate_no_download);
    
    if success
        mkdir(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges'));
        unzip(fullfile(temp_dir, 'release.zip'), fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges'));
        movefile(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges', 'releaseV3', '*'), fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges'));
        rmdir(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges', 'releaseV3'), 's');
        cd(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges'));
        if isunix
            mex private/edgesDetectMex.cpp -outdir private '-DUSEOMP' CFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"
            mex private/edgesNmsMex.cpp    -outdir private '-DUSEOMP' CFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"
        else
            % if windows
            mex private/edgesDetectMex.cpp -outdir private '-DUSEOMP' 'OPTIMFLAGS="$OPTIMFLAGS' '/openmp"'
            mex private/edgesNmsMex.cpp    -outdir private '-DUSEOMP' 'OPTIMFLAGS="$OPTIMFLAGS' '/openmp"'
        end
        fprintf(1, 'Done mex''ing\n');
        cd(curr_dir);
        replaceInTextFile(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges', 'edgesDetect.m'), '\[E,O,inds,segs\]', '[E,T,O,inds,segs]');
        replaceInTextFile(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges', 'edgesDetect.m'), '% perform nms', 'T = [];\n% perform nms');
        replaceInTextFile(fullfile(algos_dir, 'segmentation', 'boundaries--dollar_ICCV_2013_structedges', 'edgesDetect.m'), 'E\s*=\s*edgesNmsMex', 'T=edgesNmsMex');
    end

    
    % download Woodford's Image-Based Rendering and Stereo code
    success = download_code('http://www.robots.ox.ac.uk/~ojw/files/imrender_v2.4.zip', ...
        fullfile(temp_dir, 'imrender_v2.4.zip'), 'Woodford''s Image-Based Rendering and Stereo code', simulate_no_download);
    
    if success
        unzip(fullfile(temp_dir, 'imrender_v2.4.zip'), fullfile(algos_dir, 'segmentation'));
        cd(fullfile(algos_dir, 'segmentation', 'imrender', 'vgg'));
        % segment as a test - which also compiles the file
        temp = vgg_segment_gb(imread('peppers.png'), 0.5, 10, 10);
        fprintf(1, 'Done mex''ing\n');
        cd(curr_dir);
    end
    
    
    % download export_fig code
    success = download_code('https://codeload.github.com/ojwoodford/export_fig/legacy.zip/master', ...
        fullfile(temp_dir, 'ojwoodford-export_fig.zip'), 'Woodford''s matlab export fig code', simulate_no_download);
    
    if success
        mkdir(fullfile(algos_dir, 'utils'));
        unzip(fullfile(temp_dir, 'ojwoodford-export_fig.zip'), fullfile(algos_dir, 'utils'));
        d = dir(fullfile(algos_dir, 'utils', '*export_fig*'));
        movefile(fullfile(algos_dir, 'utils', d(1).name), fullfile(algos_dir, 'utils', 'export_fig'));
        replaceInTextFile(fullfile(code_root_dir, 'utils', 'drawFigFrames.m'), '~/videovolumes/extern_src', algos_dir, true);
    end
    
    
    % download Vedaldi's vlfeat code
    success = download_code('https://github.com/vlfeat/vlfeat/archive/master.zip', ...
        fullfile(temp_dir, 'vlfeat.zip'), 'Vedaldi''s vlfeat code', simulate_no_download);
    
    if success
        unzip(fullfile(temp_dir, 'vlfeat.zip'), fullfile(algos_dir, 'toolboxes'));
        d = dir(fullfile(algos_dir, 'toolboxes', '*vlfeat*'));
        movefile(fullfile(algos_dir, 'toolboxes', d(1).name), fullfile(algos_dir, 'toolboxes', 'vlfeat'));
    end
    
    
    % change the extern code path in the internal parameters script
    replaceInTextFile(fullfile(code_root_dir, 'internal_params.m'), '''/home/ahumayun/videovolumes/extern_src''', ['fullfile(fp.code_root_dir, ''', extern_src_rel, ''')'], true);

    
    % delete temp directory
    if ~simulate_no_download
        rmdir(temp_dir, 's');
    end
    
catch exception
    % remove temp dir
    rmdir(temp_dir, 's');
    rethrow(exception)
end

end


function success = download_code(url, filepath, desc, simulate_no_download)
try
    fprintf(1, 'Downloading %s ...\n', desc);
    if ~simulate_no_download
        [f, status] = urlwrite(url, filepath);
        success = status == 1;
    else
        success = true;
    end
catch exception
    success = false;
end

if success
    if ~simulate_no_download
        fprintf(1, 'Done downloading\n');
    else
        fprintf(1, 'Simulated download call\n');
    end
else
    fprintf(2, 'Downloading failure\n');
end
end


function transferMatlabFromGNU(makefilepath, dest_dir)
fd = fopen(makefilepath, 'r');
str = fread(fd);
str = char(str');
fclose(fd);

files = {};
re_matches = regexp(str, '(?:matlab)\s+:=\s+(\S+.(?:(mat)|m)(?:\s*\\?\s*((\$\(wildcard)|(\)))?\s+))*', 'tokens');
for idx = 1:length(re_matches)
    f = regexp(re_matches{idx}{1}, '(\S+.(?:(mat)|m))', 'tokens');
    files = [files cellfun(@(x)x, f)];
end
for idx = 1:length(files)
    movefile(fullfile(fileparts(makefilepath), files{idx}), dest_dir);
end
end


function adjustAttributes(folder_path)
% dont need to change file permissions on windows
if ispc == 1
    return;
end

d = dir(folder_path);
for idx = 1:length(d)
    if strcmp(d(idx).name,'.') || strcmp(d(idx).name,'..')
        continue;
    end
    
    curr_path = fullfile(folder_path,d(idx).name);
    if d(idx).isdir == 1
        adjustAttributes(curr_path);
    else
        unix(['chmod 0644 "' curr_path '"']);
    end
end
end