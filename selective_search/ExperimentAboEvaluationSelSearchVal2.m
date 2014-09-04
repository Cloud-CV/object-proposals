function [boxes]=ExperimentAboEvaluationSelSearchVal2

config=generateConfig('/home/gneelima/Selective_search_imagenet/val/','/home/gneelima/work/data/input/objectProposals/selective_search/gtImageNet13Val2.mat','/home/gneelima/work/data/output/objectProposals/selective_search/');


boxesLocation=config.path.selBoxLocation;
gtDataFile=config.list.gtIdsList;
saveLoc=config.path.outputLoc;
saveFile=[saveLoc 'selectiveSearchVal2BoxesForABOEval.mat'];

load(gtDataFile);

sel_boxes=cell(length(imagesWithObj),1);
for i=1:length(imagesWithObj)
	load([boxesLocation imagesWithObj{i} '_boxes.mat' ]);
	sel_boxes{i}=boxes;


end
size(sel_boxes)
save(saveFile,'sel_boxes','-v7.3');




