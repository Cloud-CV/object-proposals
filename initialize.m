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

addpath(genpath([pwd '/edgeBoxes']));
configjson.edgeBoxes.modelPath = [parDir, '/edgeBoxes/releaseV3/', 'models/forest/modelBsds.mat'];
configjson.edgeBoxes.params = setEdgeBoxesParamsFromConfig(configjson.edgeBoxes);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring MCG  %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath([pwd '/mcg/MCG-pre-trained']));
mcg_path = [pwd '/mcg/MCG-pre-trained'];
%set root_dir for mcg
configjson.mcg.root_dir = mcg_path;
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
%% configuring RIGOR %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring selective search %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath(fullfile(pwd,'selective_search')));
configjson.selective_search.params.colorTypes = {'Hsv', 'Lab', 'RGI', 'H', 'Intensity'};
configjson.selective_search.params.simFunctionHandles = {@SSSimColourTextureSizeFillOrig,@SSSimTextureSizeFill};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% configuring Geodesic Object Proposal %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gopPath = [pwd, '/gop_1.3'];
addpath(genpath(gopPath));
configjson.gop.gopdatapath=[gopPath '/data'];


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

%%%%%%%%%%%%%%%%%%%%%
%% configuring LPO %%
%%%%%%%%%%%%%%%%%%%%%

lpoPath = [pwd, '/lpo'];
addpath(genpath(lpoPath));
configjson.lpo.path=lpoPath;


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



fprintf('**Initialization finished. All the necessary paths have been set.**\n');


addpath(genpath([pwd, '/dependencies']));
vl_setup;
