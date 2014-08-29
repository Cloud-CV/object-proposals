function drs=ComputeDR(dets, gts, params)
assert(size(params.nWindows,1)==1 && size(params.ious,1)==1);

drs=zeros(length(params.nWindows),length(params.ious));

for j=1:length(params.ious)
  totalNCovered=0;
  totalNObjects=0;  
  nDets=size(dets,1);
  nGTBoxes=size(gts.gt.boxes,1);
  assert(nDets>0);
  nw=circshift(params.nWindows<=nDets,[0 1]);
  nw(1)=1;
  nw=params.nWindows(nw);
  [nCovered,~, ~, ~, ~, ~]=computeNCoveredBoxes(dets,gts.gt.boxes,nw, true,params.ious(j));
  nCovered=[nCovered;repmat(nCovered(end),length(params.nWindows)-length(nw),1)];
  totalNCovered=totalNCovered+nCovered;
  totalNObjects=totalNObjects+nGTBoxes;
  
  drs(:,j)=totalNCovered./totalNObjects;
end

end
