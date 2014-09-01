function config=createConfig()

config.path.input='/home/gneelima/work/data/datasets/PASCAL2007/testImages/';
config.path.output='/home/gneelima/work/data/output/objectProposals/rahtuObjectness/PASCAL2007/proposals/';

config.opts.imageExt='.jpg';
config.opts.numProposals=55555

config.params.InitialWindows.loadInitialWindows=false;
config.params.InitialWindows.windowTypes={'Prior','Superpix'};
config.params.InitialWindows.numInitialWindows=100000;
config.params.InitialWindows.numberOfConnectedSuperpix=3;
config.params.InitialWindows.windowPriorDistribution='ICCV_windowPriorDistribution.mat';

config.params.Features.loadFeatureScores=false;
config.params.Features.featureTypes={'SS','WS','BE','BI'};
config.params.Features.featureWeights=[1.685305e+00, 7.799898e-02, 3.020189e-01, -7.056292e-04];

config.params.NMS.NMStype='NMSab';
config.params.NMS.numberOfOutputWindows=1000;
config.params.NMS.numberOfIntermediateWindows=10001;
config.params.NMS.trhNMSa=0;
config.params.NMS.trhNMSb=0.75;

config.params.Storage.initialWindows=[];
config.params.Storage.features=[];
config.params.Storage.outputWindows=[];

config.params.verbose=1;



