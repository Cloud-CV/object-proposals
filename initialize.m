global configjson
    
% add current directory as the parent directory
parDir = pwd;
addpath(genpath(pwd));    
% adding evaluation metrics into path
addpath(genpath([parDir '/evaluation-metrics']));
    
% add jsonlib to path and load the config file
addpath([parDir '/jsonlab_1.0beta/jsonlab']);
fprintf('Added json encoder/decoder to the path\n');
   
configjson = loadjson([parDir, '/config.json']);
configjson.params.parDir = pwd;
    
addpath(fullfile(pwd, 'utils'));
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% configuring of edge boxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

addpath(genpath([parDir '/edgeBoxes']));
configjson.edgeBoxes.modelPath = [parDir, '/edgeBoxes/releaseV3/', 'models/forest/modelBsds.mat'];
configjson.edgeBoxes.params = setEdgeBoxesParamsFromConfig(configjson.edgeBoxes);
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring MCG  %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


mcg_path = [pwd '/mcg/MCG-Full/'];
%set root_dir for mcg
configjson.mcg.root_dir = mcg_root_dir(mcg_path);
mcg_install(configjson.mcg.root_dir);

%%%%%%%%%%%%%%%%%%%%%%%
%% configuring Endres %%%%
%%%%%%%%%%%%%%%%%%%%%%%

endres_path = [pwd '/endres/proposals'];
configjson.endres.endrespath = endres_path;
addpath(genpath(endres_path));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring rantalankila %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

addpath(genpath([pwd '/dependencies']));
addpath(genpath([pwd '/rantalankilaSegments']));
configjson.rantalankila.rapath =   [pwd '/rantalankilaSegments'];
configjson.rantalankila.vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];
spagglom_options;
configjson.rantalankila.params=opts; 

%%%%%%%%%%%%%%%%%%%%%%%
%% configuring rahtu %%
%%%%%%%%%%%%%%%%%%%%%%%
   
addpath(genpath([pwd '/rahtu']));
configjson.rahtu.rahtuPath = [pwd '/rahtu/rahtuObjectness'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring randomizedPrims %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath([pwd, '/randomizedPrims']));
configjson.randomPrim.rpPath = [pwd, '/randomizedPrims/rp-master'];
addpath([configjson.randomPrim.rpPath, '/cmex']);
%setupRandomizedPrim(configjson.randomPrim.rpPath);
GenerateRPConfig(configjson.randomPrim.rpPath);
GenerateRPConfig_4segs(configjson.randomPrim.rpPath);

params=LoadConfigFile(fullfile(configjson.randomPrim.rpPath, 'config/rp.mat'));
configjson.randomPrim.params=params;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring objectness %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath([pwd, '/objectness-release-v2.2']));
configjson.objectness.objectnesspath = [pwd, '/objectness-release-v2.2'];
params=defaultParams(configjson.objectness.objectnesspath);
configjson.objectness.params=params;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring selective search %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath(fullfile(pwd,'selective_search')));
configjson.selective_search.params.colorTypes = {'Hsv', 'Lab', 'RGI', 'H', 'Intensity'};
configjson.selective_search.params.simFunctionHandles = {@SSSimColourTextureSizeFillOrig,@SSSimTextureSizeFill};
    fprintf('Initialization finished. All the necessary paths have been set.\n ');


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


    
