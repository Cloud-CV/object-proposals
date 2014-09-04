% Compile All  object proposals

% add current directory as the parent directory
	parDir = pwd;


% add jsonlib to path and load the config file
	addpath([parDir '/jsonlab_1.0beta/jsonlab']);
	fprintf('Added json encoder/decoder to the path\n');
    global configjson
	configjson = loadjson([parDir, '/config.json']);
    addpath(fullfile(pwd, 'utils'));

%% compilation of edge boxes
	mex edgeBoxes/releaseV3/private/edgesDetectMex.cpp -outdir edgeBoxes/releaseV3/private/ 
	mex edgeBoxes/releaseV3/private/edgesNmsMex.cpp -outdir edgeBoxes/releaseV3/private/ 
	mex edgeBoxes/releaseV3/private/spDetectMex.cpp -outdir edgeBoxes/releaseV3/private/
	mex edgeBoxes/releaseV3/private/edgeBoxesMex.cpp -outdir edgeBoxes/releaseV3/private/

	addpath(genpath([parDir '/edgeBoxes']));
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

%Validation Code