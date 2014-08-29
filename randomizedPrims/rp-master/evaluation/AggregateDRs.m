function AggregateDRs(resDir, parsedVOCDir, evalParams)

assert(resDir(1)=='/');

aggDir=[resDir '/aggregated_drs/'];
if(exist(aggDir, 'dir') ~= 0)
  disp(['The aggregatedDRs dir: ' aggDir ' already exists. Press any key to use it (or delete it to parse it again)...']);
  pause;
  return;
end
mkdir(aggDir);
aggFile=[aggDir '/drs.mat'];

nRuns = 1;

d = dir(resDir);
nImages = numel(d) - 3;
drs = cell(nRuns, 1);
for r = 1: nRuns

  %Process first scene
  i=1;
  drsFile = [resDir '/res_' num2str(i) '.mat'];
  assert(exist(drsFile,'file')~=0);
  eval=load(drsFile);
  gt = load([parsedVOCDir '/gt_' num2str(i) '.mat']);
  nGTObjects=size(gt.gt.boxes, 1);
  
  totalDrs= eval.results.drs.*nGTObjects;
  totalObjects=nGTObjects;
  
  
  for i=2:nImages
    
    drsFormat=[resDir '/res_%d.mat'];
    drsFile=sprintf(drsFormat,i);

    assert(exist(drsFile,'file')~=0);
    eval=load(drsFile);
    gt = load([parsedVOCDir '/gt_' num2str(i) '.mat']);
    nGTObjects=size(gt.gt.boxes, 1);
    
    totalDrs=totalDrs+eval.results.drs.*nGTObjects;
    totalObjects=totalObjects+nGTObjects;
  end
  
  drs{r}=totalDrs./totalObjects;
  
  totalObjects
  
  assert(~(any(any(drs{r}>1)) || any(any(drs{r}<0))));

end

drs = cat(3,drs{:});

ious=eval.results.ious;
nWindows=eval.results.nWindows;
  
save(aggFile,'drs','ious','nWindows');

end



























