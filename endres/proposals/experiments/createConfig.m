function config=createConfig()

config.path.input='/home/gneelima/work/data/datasets/PASCAL2007/testImages/';
config.path.output='/home/gneelima/work/data/output/objectProposals/catIndObjProposals/proposals/';
config.opts.imageExt='.jpg';
config.opts.numProposals=100;

%{
config.train.params.nsegments=nsegments;
config.train.params.ncv=ncv;
config.train.params.labeltol=labeltol;
config.train.params.nclasses=nclasses;

config.train.imdir=imdir;
config.train.datadir=datadir;
config.train.outdir=datadir;
%}


