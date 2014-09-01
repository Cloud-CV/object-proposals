function config=createConfig()

config.path.input='/home/gneelima/work/data/datasets/PASCAL2007/testImages/';
config.path.output='/home/gneelima/work/data/output/objectProposals/randomizedPrims/PASCAL2007/proposals/';

config.opts.imageExt='.jpg';



config.params.rSeedForRun=-1;
config.params.approxFinalNBoxes=10000;
config.params.q=10; 

config.params.segmentations{1}.colorspace='LAB';

config.params.segmentations{1}.superpixels.sigma=0.8;
config.params.segmentations{1}.superpixels.c=100;
config.params.segmentations{1}.superpixels.min_size=100;

config.params.segmentations{1}.simWeights.wBias=3.0017;
config.params.segmentations{1}.simWeights.wCommonBorder=-1.0029;
config.params.segmentations{1}.simWeights.wLABColorHist=-2.6864;
config.params.segmentations{1}.simWeights.wSizePer=-2.3655;

config.params.segmentations{1}.alpha=ones(1,65536);
config.params.segmentations{1}.verbose=1;


