    global configjson
    
% add current directory as the parent directory
	parDir = pwd;
    
% adding evaluation metrics into path
    addpath([parDir '/evaluation-metrics']);
    
% add jsonlib to path and load the config file
	addpath([parDir '/jsonlab_1.0beta/jsonlab']);
	fprintf('Added json encoder/decoder to the path\n');
    
    configjson = loadjson([parDir, '/config.json'])
    configjson.params.parDir = pwd;
    
    addpath(fullfile(pwd, 'utils'));
    
	addpath(genpath([parDir '/edgeBoxes']));
    configjson.edgeBoxes.modelPath = [parDir, '/edgeBoxes/releaseV3/', 'models/forest/modelBsds.mat']
	configjson.edgeBoxes.params = setEdgeBoxesParamsFromConfig(configjson.edgeBoxes);
	

    mcg_path = [pwd '/mcg/MCG-Full'];
	addpath(mcg_path);
	addpath([pwd '/mcg/API'])
	%set root_dir for mcg
	configjson.mcg.root_dir = mcg_root_dir(mcg_path);
    mcg_install(configjson.mcg.root_dir);
    %configjson.mcg.db_root_dir = database_root_dir(configjson.mcg);

    endres_path = [pwd '/endres/proposals'];
    configjson.endres.endrespath = endres_path;
	addpath(genpath(endres_path));

    addpath(genpath([pwd '/dependencies']));
	addpath(genpath([pwd '/rantalankilaSegments']));
	configjson.rantalankila.rapath =   [pwd '/rantalankilaSegments'];
	configjson.rantalankila.vlfeatpath = [ pwd '/dependencies/vlfeat-0.9.16/' ];
    
    addpath(genpath([pwd '/rahtu']));
	configjson.rahtu.rahtuPath = [pwd '/rahtu/rahtuObjectness'];
	
    addpath(genpath([pwd, '/randomizedPrims']));
	configjson.randomPrim.rpPath = [pwd, '/randomizedPrims/rp-master'];
    addpath([configjson.randomPrim.rpPath, '/cmex']);
    
    addpath(genpath([pwd, '/objectness-release-v2.2']));
    configjson.objectness.objectnesspath = [pwd, '/objectness-release-v2.2'];
    
    addpath(genpath(fullfile(pwd,'selective_search')));
	configjson.selective_search.params.colorTypes = {'Hsv', 'Lab', 'RGI', 'H', 'Intensity'};
	configjson.selective_search.params.simFunctionHandles = {@SSSimColourTextureSizeFillOrig, ...
                      @SSSimTextureSizeFill};
    fprintf('Initialization finished. All the necessary paths have been set.\n ');


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


    