global configjson
    
% add current directory as the parent directory
parDir = pwd;
% adding evaluation metrics into path
addpath(genpath([parDir '/evaluation-metrics']));
% add jsonlib to path and load the config file
addpath([parDir '/jsonlab_1.0beta/jsonlab']);
    
fprintf('Added json encoder/decoder to the path\n');
    
configjson = loadjson([parDir, '/config.json']);
configjson.params.parDir = pwd;
    
addpath(fullfile(pwd, 'utils'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% compilation of edge boxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
	cd edgeBoxes/releaseV3/private/;
	mex edgesDetectMex.cpp
	mex edgesNmsMex.cpp 
	mex spDetectMex.cpp 
	mex edgeBoxesMex.cpp
	cd(parDir)
   
	addpath(genpath([parDir '/edgeBoxes']));
        configjson.edgeBoxes.modelPath = [parDir, '/edgeBoxes/releaseV3/', 'models/forest/modelBsds.mat'];
	configjson.edgeBoxes.params = setEdgeBoxesParamsFromConfig(configjson.edgeBoxes);
        fprintf('Compilation of Edge Boxes finished\n ');
catch
        fprintf('Compilation of Edge Boxes failed\n ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building MCG and installation%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
	mcg_path = [pwd '/mcg/MCG-Full'];
	addpath(genpath(mcg_path));
	addpath([pwd '/mcg/API']);
	%set root_dir for mcg
	configjson.mcg.root_dir = mcg_root_dir(mcg_path);

	%build and install
	mcg_build(configjson.mcg.root_dir, configjson.mcg.opts.boostpath);
	mcg_install(configjson.mcg.root_dir);

	%set databse root directory
	% configjson.mcg.db_root_dir = database_root_dir(configjson.mcg);
catch
    fprintf('Compilation of MCG failed\n ');
end


%%%%%%%%%%%%%%%%%%%%%%%
%% building Endres %%%%
%%%%%%%%%%%%%%%%%%%%%%%
try
    endres_path = [pwd '/endres/proposals'];
    configjson.endres.endrespath = endres_path;
    addpath(genpath(endres_path));
catch
    fprintf('Compilation of Endres failed\n ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building rantalankila %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of Rantalankila Segments started\n ');
    addpath(genpath([pwd '/dependencies']));
    addpath(genpath([pwd '/rantalankilaSegments']));
    configjson.rantalankila.rapath =   [pwd '/rantalankilaSegments'];
    configjson.rantalankila.vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];
    run(fullfile(configjson.rantalankila.vlfeatpath, 'toolbox/vl_setup'));
    cd([pwd '/dependencies/GCMex/']);
    GCMex_compile;
    cd(parDir);
    spagglom_options;
    configjson.rantalankila.params=opts;
    fprintf('Compilation of Rantalankila Segments finished\n ');
catch
    fprintf('Compilation of Rantalankila failed\n ');
end

%%%%%%%%%%%%%%%%%%%%
%% building rahtu %%
%%%%%%%%%%%%%%%%%%%%

try
    fprintf('Compilation of Rahtu started\n ');
    addpath(genpath([pwd '/rahtu']));
    configjson.rahtu.rahtuPath = [pwd '/rahtu/rahtuObjectness'];
    compileObjectnessMex(configjson.rahtu.rahtuPath);
    fprintf('Compilation of Rahtu finished\n ');
catch
    fprintf('Compilation of Edge Boxes failed\n ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building randomizedPrims%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of Randomized Prims started\n ');
    addpath(genpath([pwd, '/randomizedPrims']));
    configjson.randomPrim.rpPath = [pwd, '/randomizedPrims/rp-master'];
    setupRandomizedPrim(configjson.randomPrim.rpPath);
    params=LoadConfigFile(fullfile(configjson.randomPrim.rpPath, 'config/rp.mat'));
    configjson.randomPrim.params=params;
    addpath([configjson.randomPrim.rpPath, '/cmex']);
    fprintf('Compilation of Randomized Prims finished\n ');
catch
    fprintf('Compilation of Randomized Prims failed\n ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%% building objectness %%
%%%%%%%%%%%%%%%%%%%%%%%%%

try
    fprintf('Compiling Objectness \n');
    addpath(genpath([pwd, '/objectness-release-v2.2']));
    configjson.objectness.objectnesspath = [pwd, '/objectness-release-v2.2'];
    params=defaultParams(configjson.objectness.objectnesspath);

    configjson.objectness.params=params;
    fprintf('Compiling Objectness finished \n');
catch
   fprintf('Compilation of Objectness failed\n ');
end
%% building selective_search
try
	fprintf('Compiling Selective Search \n');
	mex 'selective_search/Dependencies/anigaussm/anigauss_mex.c' 'selective_search/Dependencies/anigaussm/anigauss.c' -output anigauss -outdir 'selective_search'
	mex 'selective_search/Dependencies/mexCountWordsIndex.cpp' -outdir 'selective_search'
	mex 'selective_search/Dependencies/FelzenSegment/mexFelzenSegmentIndex.cpp' -output mexFelzenSegmentIndex -outdir 'selective_search'
	addpath(genpath(fullfile(pwd,'selective_search')));
	configjson.selective_search.params.colorTypes = {'Hsv', 'Lab', 'RGI', 'H', 'Intensity'};
	configjson.selective_search.params.simFunctionHandles = {@SSSimColourTextureSizeFillOrig, ...
                      @SSSimTextureSizeFill};
    fprintf('Compiling Selective Search finished \n');

catch
    fprintf('Compilation of Selective Search failed\n ');
end



%%%%%%%%%%%%%%%%%%%%
%% building rigor %%
%%%%%%%%%%%%%%%%%%%%

try
	
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
   
       fprintf('Compiling RIGOR finished \n');

catch
    fprintf('Compilation of RIGOR failed\n ');
end



%Validation Code


%%
proposalNames = fieldnames(configjson);
for i = 1:length(proposalNames)
    if((strcmp(proposalNames(i), 'imageLocation')==1 || strcmp(proposalNames(i), 'outputLocation')==1 || strcmp(proposalNames(i), 'params')==1))
        continue;
    else    
        eval(sprintf('configjson.%s.opts.outputLocation = fullfile(configjson.outputLocation,proposalNames(i));',char(proposalNames(i))))
        eval(sprintf('configjson.%s.opts.name = proposalNames(i);',  char(proposalNames(i)) ))
        eval(sprintf('configjson.%s.opts.color = (randi(256,1,3)-1)/256;',  char(proposalNames(i))  ))

    end
end

