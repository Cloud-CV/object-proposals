function preprocessGtData(config)
% make the gt boxes consistent with selective search boxes

gtIdsList=config.list.gtIdsList;

load(gtIdsList);

selSearchConsistentGtBoxes=cell(length(gtBoxes));

for i=1:length(gtBoxes)
tmp=gtBoxes{i};
selSearchConsistentGtBoxes{i}=[tmp(:,2),tmp(:,1), tmp(:,4), tmp(:,3)];
end

save(gtIdsList,'selSearchConsistentGtBoxes','-append');






