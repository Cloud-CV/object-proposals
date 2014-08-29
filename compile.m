% Compile All  object proposals

% add current directory as the parent directory
	parDir = pwd;


% add jsonlib to path and load the config file
	addpath([parDir '/jsonlab_1.0beta/jsonlab']);
	fprintf('Added json encoder/decoder to the path\n');
    global configjson
	configjson = loadjson([parDir, '/config.json']);


%% compilation of edge boxes
	mex edgeBoxes/releaseV3/private/edgesDetectMex.cpp
	mex edgeBoxes/releaseV3/private/edgesNmsMex.cpp
	mex edgeBoxes/releaseV3/private/spDetectMex.cpp
	mex edgeBoxes/releaseV3/private/edgeBoxesMex.cpp

	addpath(genpath([parDir '/edgeBoxes']));

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
	addpath(genpath(endres_path));

%% building rantalankila
	addpath(genpath([pwd '/dependencies']));
	addpath(genpath([pwd '/rantalankilaSegments']));
	configjson.rantalankila.rantalankilapath =   [pwd '/rantalankilaSegments'];
	confgjson.rantalankila.vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];

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

%Validation Code