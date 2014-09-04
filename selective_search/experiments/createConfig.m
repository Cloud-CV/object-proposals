function config=createConfig()


colorTypes = {'Hsv', 'Lab'};
simFunctionHandles = {@SSSimColourTextureSizeFillOrig, ...
                      @SSSimTextureSizeFill};

ks = [50 100];
sigma = 0.8;
minBoxWidth = 20;
imWidth=500;
mode='fast';
numProposals=10000;

config.params.colorTypes=colorTypes;
config.params.simFunctionHandles=simFunctionHandles;
config.params.ks=ks;
config.params.sigma=sigma;
config.parmas.minBoxWidth=minBoxWidth;
config.params.imWidth=imWidth;

config.opts.mode=mode;
config.opts.numProposals=numProposals;
config.opts.imageExt='.jpg';


config.path.input='/home/gneelima/work/data/datasets/PASCAL2007/testImages/';
config.path.output='/home/gneelima/work/data/output/objectProposals/selective_search/PASCAL2007/proposals/';
