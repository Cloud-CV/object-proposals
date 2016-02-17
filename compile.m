global configjson

% add current directory as the parent directory
parDir = pwd;
% adding evaluation metrics into path
% add jsonlib to path and load the config file


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% pDollarToolBox compiling %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
      pDollarToolBoxPath=[pwd '/dependencies/pDollarToolbox'];
      addpath(genpath(pDollarToolBoxPath));
      toolboxCompile;

catch exc
      fprintf('Piotr Dollar tool box compilation failed\n');
      fprintf(exc.message);
      fprintf('***************************\n');
      cd(parDir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%compiling structured edge detector %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
	cd dependencies/structuredEdges/release/private;
        mex edgesDetectMex.cpp
        mex edgesNmsMex.cpp
        mex spDetectMex.cpp
        mex edgeBoxesMex.cpp
        cd(parDir)
 	fprintf('Compilation of Structured edge detector sucessfully finished\n ');
        fprintf('***************************\n');
catch exc
	fprintf('Compilation of structured edge detector failed\n ');
        fprintf(exc.message);
        fprintf('***************************\n');
        cd(parDir);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%compiling vlfeat%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    vlDir = [parDir '/dependencies/vlfeat-0.9.16/toolbox'];
    cd(vlDir);
    vl_setup;
    cd(parDir);
catch exc
    fprintf('Compilation of vlfeat failed\n ');
        fprintf(exc.message);
        fprintf('***************************\n');
     cd(parDir);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% compilation of edge boxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
	fprintf('Compilation of Edge Boxes started\n ');
	cd edgeBoxes/releaseV3/private/;
	mex edgesDetectMex.cpp
	mex edgesNmsMex.cpp
	mex spDetectMex.cpp
	mex edgeBoxesMex.cpp
	cd(parDir)

        fprintf('Compilation of Edge Boxes sucessfully finished\n ');
	fprintf('***************************\n');
catch exc
        fprintf('Compilation of Edge Boxes failed\n ');
	fprintf(exc.message);
	fprintf('***************************\n');
        cd(parDir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building MCG and installation%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
	fprintf('Compilation of MCG started\n ');
	mcg_path = [pwd '/mcg/MCG-pre-trained'];
	addpath(genpath([pwd '/mcg/MCG-pre-trained']));
	%set root_dir for mcg
	mcgRootDir = mcg_path;
        boostPath='/opt/local/include/';
	%build and install
	mcg_build(parDir, mcgRootDir, boostPath);
	%mcg_install(mcgRootDir);
	fprintf('Compilation of MCG sucessfully finished\n ');
        fprintf('***************************\n');
catch exc
    fprintf('Compilation of MCG failed\n ');
    fprintf(exc.message);
    fprintf('***************************');
    cd(parDir);
end


%%%%%%%%%%%%%%%%%%%%%%%
%% building Endres %%%%
%%%%%%%%%%%%%%%%%%%%%%%
%noothing to do

try
     fprintf('Compilation of Endres started\n ');
    endres_path = [pwd '/endres/proposals'];
    %configjson.endres.endrespath = endres_path;
    %addpath(genpath(endres_path));
    cd(endres_path);
    endres_compile;
    cd(parDir);
    fprintf('Compilation of Endres sucessfully finished\n ');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of Endres failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building rantalankila %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of Rantalankila Segments started\n ');
    vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];
    run(fullfile(vlfeatpath, 'toolbox/vl_setup'));
    cd([pwd '/dependencies/GCMex/']);
    GCMex_compile;
    cd(parDir);
    fprintf('Compilation of Rantalankila Segments successfully finished\n ');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of Rantalankila failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end

%%%%%%%%%%%%%%%%%%%%
%% building rahtu %%
%%%%%%%%%%%%%%%%%%%%

try
    fprintf('Compilation of Rahtu started\n ');
    addpath(genpath([pwd '/rahtu']));
    rahtuPath = [pwd '/rahtu/rahtuObjectness'];
    compileObjectnessMex(parDir, rahtuPath);
    fprintf('Compilation of Rahtu successfully finished\n ');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of Rahtu failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building randomizedPrims%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of Randomized Prims started\n ');
    rpPath = [pwd, '/randomizedPrims/rp-master'];
    addpath(genpath(rpPath))
    setupRandomizedPrim(rpPath);
    fprintf('Compilation of Randomized Prims successfully finished\n ');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of Randomized Prims failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%% building objectness %%
%%%%%%%%%%%%%%%%%%%%%%%%%

%nothing to do

try
    fprintf('Compiling Objectness \n');
    %addpath(genpath([pwd, '/objectness-release-v2.2']));
    %configjson.objectness.objectnesspath = [pwd, '/objectness-release-v2.2'];
    %params=defaultParams(configjson.objectness.objectnesspath);

    %configjson.objectness.params=params;
    cd objectness-release-v2.2/MEX;
    mex slidingWindowComputeScore.c;
    mex scoreSamplingMex.c;
    mex NMS_sampling.c;
    mex nms4d.c;
    mex computeScoreContrast.c;
    mex computeIntegralHistogramMex.c;
    cd(parDir);
    fprintf('Compiling Objectness succesfully finished \n');
    fprintf('***************************\n');
catch exc
   fprintf('Compilation of Objectness failed\n ');
   fprintf(exc.message);
   fprintf('***************************\n');
   cd(parDir);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% building selective_search %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
	fprintf('Compiling Selective Search \n');
	mex 'selective_search/Dependencies/anigaussm/anigauss_mex.c' 'selective_search/Dependencies/anigaussm/anigauss.c' -output anigauss -outdir 'selective_search'
	mex 'selective_search/Dependencies/mexCountWordsIndex.cpp' -outdir 'selective_search'
	mex 'selective_search/Dependencies/FelzenSegment/mexFelzenSegmentIndex.cpp' -output mexFelzenSegmentIndex -outdir 'selective_search'
    fprintf('Compiling Selective Search succesfully finished \n');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of Selective Search failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end



%%%%%%%%%%%%%%%%%%%%
%% building rigor %%
%%%%%%%%%%%%%%%%%%%%
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
   addpath(genpath(rigor_path));
   addpath([pwd '/rigor/API']);
  % make

  %  addpath(genpath([pwd '/dependencies']));
   % find locations of files
   code_root_dir = fullfile(fileparts(which(mfilename)), 'rigor/rigor_src');
   utils_dir = fullfile(code_root_dir, 'utils');
   extern_dir = fullfile(code_root_dir, 'extern_src');
   boykov_dir = fullfile(code_root_dir, 'boykov_maxflow');
try

  fprintf('eval statements\n');
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

       fprintf('Compiling RIGOR succesfully finished \n');

catch exc
    fprintf('Compilation of RIGOR failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Building Geodesic Object Proposals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of Geodesic Object Proposals started\n ');
    gopPath = [pwd, '/gop_1.3/matlab'];
    addpath(genpath(gopPath));
    cd(gopPath);
    compile();
    %%system(sprintf('cp %s/gop_mex.mexa64.compiled %s/gop_mex.mexa64',pwd,pwd));
    cd(parDir);
    fprintf('Compilation of Geodesic Object Proposals  successfully finished\n ');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of Geodesic Object Proposals failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end

%%%%%%%%%%%%%%%%%%
%% Building LPO %%
%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of LPO started\n ');
    lpoPath = [pwd, '/lpo/matlab'];
    addpath(genpath(lpoPath));
    cd(lpoPath);
    compile();
    %%system(sprintf('cp %s/gop_mex.mexa64.compiled %s/gop_mex.mexa64',pwd,pwd));
    cd(parDir);
    fprintf('Compilation of LPO  successfully finished\n ');
    fprintf('***************************\n');
catch exc
    fprintf('Compilation of LPO failed\n ');
    fprintf(exc.message);
    fprintf('***************************\n');
    cd(parDir);
end

  fprintf('******Compiling complete.*********\n')
