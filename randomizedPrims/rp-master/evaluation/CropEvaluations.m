function [cropped,legendStr]=CropEvaluations(evals, nWindowsRange, iouRange,oLegendStr)
minNWindows = nWindowsRange(1);
maxNWindows = nWindowsRange(2);
minIou = iouRange(1);
maxIou = iouRange(2);
assert(minNWindows<=maxNWindows && minIou<=maxIou);

nEvals=numel(evals);
cropped=[];
legendStr={};
nAccepted=1;
for k=1:nEvals
  if(~(minNWindows<=evals{k}.nWindows(end) && maxNWindows>=evals{k}.nWindows(1) && minIou<=evals{k}.ious(end) && maxIou>=evals{k}.ious(1)))
    disp(['WARNING: The method ' oLegendStr{k} ' has no curve for the region so it will be omitted.']);
  else
    iMin=FindFirstBiggerThan(evals{k}.nWindows,minNWindows);
    iMax=FindLastSmallerThan(evals{k}.nWindows,maxNWindows);
    jMin=FindFirstBiggerThan(evals{k}.ious,minIou);
    jMax=FindLastSmallerThan(evals{k}.ious,maxIou);
    legendStr{nAccepted}=oLegendStr{k};
    cropped{nAccepted}.nWindows=evals{k}.nWindows(iMin:iMax);
    cropped{nAccepted}.ious=evals{k}.ious(jMin:jMax);
    cropped{nAccepted}.drs=evals{k}.drs(iMin:iMax,jMin:jMax,:);
    nAccepted=nAccepted+1;
  end
  
end

end

function iMin=FindFirstBiggerThan(vector,minValue)
for i=1:length(vector)
  if(vector(i)>=minValue)
    iMin=i;
    return;
  end
end
end

function iMax=FindLastSmallerThan(vector,maxValue)
for i=length(vector):-1:1
  if(vector(i)<=maxValue)
    iMax=i;
    return;
  end
end
end