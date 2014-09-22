% Compile All  object proposals
    global configjson
    
% add current directory as the parent directory
	parDir = pwd;
    
% adding evaluation metrics into path
    addpath([parDir '/evaluation-metrics']);
    
% add jsonlib to path and load the config file
	addpath([parDir '/jsonlab_1.0beta/jsonlab']);
	fprintf('Added json encoder/decoder to the path\n');
    
    configjson = loadjson([parDir, '/config.json'])
    configjson.parDir = pwd;
    
    addpath(fullfile(pwd, 'utils'));

%% compilation of edge boxes
	mex edgeBoxes/releaseV3/private/edgesDetectMex.cpp -outdir edgeBoxes/releaseV3/private/ 
	mex edgeBoxes/releaseV3/private/edgesNmsMex.cpp -outdir edgeBoxes/releaseV3/private/ 
	mex edgeBoxes/releaseV3/private/spDetectMex.cpp -outdir edgeBoxes/releaseV3/private/
	mex edgeBoxes/releaseV3/private/edgeBoxesMex.cpp -outdir edgeBoxes/releaseV3/private/

	addpath(genpath([parDir '/edgeBoxes']));
    configjson.edgeBoxes.modelPath = [parDir, '/edgeBoxes/releaseV3/', 'models/forest/modelBsds.mat']
	configjson.edgeBoxes.params = setEdgeBoxesParamsFromConfig(configjson.edgeBoxes);
	fprintf('Compilation of Edge Boxes finished\n ');

%% building MCG and installation
	mcg_path = [pwd '/mcg/MCG-Full'];
	addpath(mcg_path);
	addpath([pwd '/mcg/API'])
	%set root_dir for mcg
	configjson.mcg.root_dir = mcg_root_dir(mcg_path);

	%build and install
	mcg_build(configjson.mcg.root_dir, configjson.mcg.boostpath);
	mcg_install(configjson.mcg.root_dir);

	%set databse root directory
	configjson.mcg.db_root_dir = database_root_dir(configjson.mcg);

%% building Endres 
	endres_path = [pwd '/endres/proposals'];
    configjson.endres.endrespath = endres_path;
	addpath(genpath(endres_path));

%% building rantalankila
    fprintf('Compilation of Rantalankila Segments started\n ');
	addpath(genpath([pwd '/dependencies']));
	addpath(genpath([pwd '/rantalankilaSegments']));
	configjson.rantalankila.rapath =   [pwd '/rantalankilaSegments'];
	configjson.rantalankila.vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];
    fprintf('Compilation of Rantalankila Segments finished\n ');
    
%% building rahtu
    fprintf('Compilation of Rahtu started\n ');
	addpath(genpath([pwd '/rahtu']));
	configjson.rahtu.rahtuPath = [pwd '/rahtu/rahtuObjectness'];
	compileObjectnessMex(configjson.rahtu.rahtuPath);
    fprintf('Compilation of Rahtu finished\n ');
%% building randomizedPrims
    fprintf('Compilation of Randomized Prims started\n ');
	addpath(genpath([pwd, '/randomizedPrims']));
	configjson.randomPrim.rpPath = [pwd, '/randomizedPrims/rp-master'];
	setupRandomizedPrim(configjson.randomPrim.rpPath);
    addpath([configjson.randomPrim.rpPath, '/cmex']);
    fprintf('Compilation of Randomized Prims finished\n ');
%% building objectness
    fprintf('Compiling Objectness \n');
    addpath(genpath([pwd, '/objectness-release-v2.2']));
    configjson.objectness.objectnesspath = [pwd, '/objectness-release-v2.2'];
    fprintf('Compiling Objectness finished \n');
%% building selective_search
	fprintf('Compiling Selective Search \n');
	mex 'selective_search/Dependencies/anigaussm/anigauss_mex.c' 'selective_search/Dependencies/anigaussm/anigauss.c' -output anigauss -outdir 'selective_search'
	mex 'selective_search/Dependencies/mexCountWordsIndex.cpp' -outdir 'selective_search'
	mex 'selective_search/Dependencies/FelzenSegment/mexFelzenSegmentIndex.cpp' -output mexFelzenSegmentIndex -outdir 'selective_search'
	addpath(genpath(fullfile(pwd,'selective_search')));
	configjson.selective_search.params.colorTypes = {'Hsv', 'Lab', 'RGI', 'H', 'Intensity'};
	configjson.selective_search.params.simFunctionHandles = {@SSSimColourTextureSizeFillOrig, ...
                      @SSSimTextureSizeFill};



%% building rigor

fprintf('Compiling Rigor \n');
tbb_incl_opt = '';
tbb_lib_opt = '';
boost_incl_opt = '';
boost_lib_opt = '';
extra_opts = '';

% set directories and options
if ispc
    % if windows
    tbb_dir = 'D:/tbb42';
    tbb_incl_dir = fullfile(tbb_dir, 'include');
    tbb_libs = fullfile(tbb_dir, 'lib/intel64/vc12');
    boost_dir = 'D:/boost/1.55.0/VC/11.0';
    boost_libs = fullfile(boost_dir, 'stage/lib');
    
    tbb_incl_opt = ['-I', tbb_incl_dir];
    tbb_lib_opt = ['-L', tbb_libs];
    boost_incl_opt = ['-I', boost_dir];
    boost_lib_opt = ['-L', boost_libs];
elseif ismac
    % if mac
else
    % if unix/linux
    fprintf('linux var set for rigor \n');
    boost_libs = '/usr/local/lib';
    boost_lib_opt = ['-L', boost_libs];
    extra_opts = '-lrt';
end
rigor_path = [pwd '/rigor/rigor_src'];
addpath(rigor_path);
addpath([pwd '/rigor/API'])
	
% find locations of files
code_root_dir = fullfile(fileparts(which(mfilename)), 'rigor/rigor_src');
utils_dir = fullfile(code_root_dir, 'utils');
extern_dir = fullfile(code_root_dir, 'extern_src');
boykov_dir = fullfile(code_root_dir, 'boykov_maxflow');
fprintf('eval statements');
% mex code
eval(sprintf('mex -O %s/intens_pixel_diff_mex.c -output %s/intens_pixel_diff_mex', utils_dir, utils_dir));
eval(sprintf('mex -O %s/prctile_feats.cpp -output %s/prctile_feats', utils_dir, utils_dir));
eval(sprintf('mex -O %s/region_centroids_mex.cpp -output %s/region_centroids_mex', utils_dir, utils_dir));
eval(sprintf('mex -O %s/superpix_regionprops.cpp -output %s/superpix_regionprops', utils_dir, utils_dir));
eval(sprintf('mex -O %s/sp_conncomp_mex.cpp %s -output %s/sp_conncomp_mex', utils_dir, boost_incl_opt, utils_dir));
eval(sprintf(['mex -O ', ...
    '%s/segm_overlap_mex.cpp ', ...
    '%s/overlap.cpp ', ...
    '-output %s/segm_overlap_mex'], utils_dir, utils_dir, utils_dir));
eval(sprintf('mex -O %s/convert_masks.cpp -output %s/convert_masks', utils_dir, utils_dir));
eval(sprintf(['mex -O ', ...
    '%s/overlap_over_threshold.cpp ', ...
    'CFLAGS="\\$CFLAGS -fopenmp" LDFLAGS="\\$LDFLAGS -fopenmp" ', ...
    '-output %s/overlap_over_threshold'], utils_dir, utils_dir));
eval(sprintf('mex -O %s/para_pseudoflow/hoch_pseudo_par.c -output %s/para_pseudoflow/hoch_pseudo_par', extern_dir, extern_dir));
eval(sprintf(['mex -O ', ...
    '%s/bk_dynamicgraphs_mex.cpp ', ...
    '%s/dynamicgraphs/bk_nodynamic.cpp ', ...
    '%s/dynamicgraphs/bk_kohli.cpp ', ...
    '%s/dynamicgraphs/bk_multiseeddynamic.cpp ', ...
    '%s/dynamicgraphs/bk_utils.cpp %s %s %s -ltbb ', ...
    'LDFLAGS="\\$LDFLAGS %s -lboost_system-mt -lboost_timer-mt %s" ', ...
    '-output %s/bk_dynamicgraphs_mex;'], ...
    boykov_dir, boykov_dir, boykov_dir, boykov_dir, boykov_dir, ...
    boost_incl_opt, tbb_incl_opt, tbb_lib_opt, boost_lib_opt, ...
    extra_opts, boykov_dir));


%Validation Code
