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


%% building MCG and installation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
	mcg_path = [pwd '/mcg/MCG-Full'];
	addpath(genpath(mcg_path));
	addpath([pwd '/mcg/API'])
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
%% building Endres
%%%%%%%%%%%%%%%%%%%%%%%%5
try
    endres_path = [pwd '/endres/proposals'];
    configjson.endres.endrespath = endres_path;
    addpath(genpath(endres_path));
catch
    fprintf('Compilation of Endres failed\n ');
end

%%%%%%%%%%%%%%%%%%%%%%%
%% building rantalankila
%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('Compilation of Rantalankila Segments started\n ');
    addpath(genpath([pwd '/dependencies']));
    addpath(genpath([pwd '/rantalankilaSegments']));
    configjson.rantalankila.rapath =   [pwd '/rantalankilaSegments'];
    configjson.rantalankila.vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];
    run(fullfile(configjson.rantalankila.vlfeatpath, 'toolbox/vl_setup'))
    spagglom_options;
    configjson.rantalankila.params=opts;
    fprintf('Compilation of Rantalankila Segments finished\n ');
catch
    fprintf('Compilation of Rantalankila failed\n ');
end

%%%%%%%%%%%%%%%%%%%
%% building rahtu
%%%%%%%%%%%%%%%%%%%

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
    configjson.randomPrim.rpPath = [pwd, '/randomizedPrims/rp-master']
    fprintf('doind setuup')
    setupRandomizedPrim(configjson.randomPrim.rpPath)
    params=LoadConfigFile(fullfile(configjson.randomPrim.rpPath, 'config/rp.mat'))
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
    params=defaultParams(configjson.objectness.objectnesspath)

    configjson.objectness.params=params
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

%%
proposalNames = fieldnames(configjson);
for i = 1:length(proposalNames)
    if((strcmp(proposalNames(i), 'imageLocation')==1 || strcmp(proposalNames(i), 'outputLocation')==1 || strcmp(proposalNames(i), 'params')==1))
        continue;
    else    
        eval(sprintf('configjson.%s.opts.outputLocation = fullfile(configjson.outputLocation,proposalNames(i))',char(proposalNames(i))))
        eval(sprintf('configjson.%s.opts.name = proposalNames(i)',  char(proposalNames(i)) ))
        eval(sprintf('configjson.%s.opts.color = (randi(256,1,3)-1)/256',  char(proposalNames(i))  ))

    end
end
