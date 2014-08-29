clc;
close all;
clear;

mDir = fileparts(mfilename('fullpath'));
cd(mDir);
addpath(genpath('../'));

%% Params:

exp = 'ALL_4_SEGS'; % Select which configuration to use: 'JUST_LAB_SEG', 'ALL_4_SEGS'
calcInLog=false; %false (for linear vus), true (for logarithmic vus)

%Change these paths:
originalVOCDirectory = TOFILL; %Top directory of VOC 2007 dataset
parsedVOCDir = TOFILL; %Directory where parsed VOC07 will be stored

%VOC params:

imgListDir= 'complete_test_set.txt'; %File with ids of the 4952 images of the test set

params.includeBoxesWithClasses={'aeroplane', 'bicycle','boat','bottle','bus','chair','diningtable','horse','motorbike','person','pottedplant','sofa','train','tvmonitor'};
params.omitImagesWithClasses={'bird','car','cat','cow','dog','sheep'};
params.considerDifficult=true;

nMaximumWindows = 10000;
evalParams.nWindows = unique(round(logspace(0, log10(nMaximumWindows), 100)));
evalParams.ious = 0 : 0.05 : 1;

if(strcmp(exp, 'ALL_4_SEGS'))
  configFile = '../config/rp_4segs.mat'; 
  proposalsDir = [mDir '/tmp_prop_dir'];
elseif(strcmp(exp, 'JUST_LAB_SEG'))
  configFile = '../config/rp.mat';
  proposalsDir = [mDir '/tmp_prop_dir_lab'];
else
  assert(false);
end
resultDirs={proposalsDir};


%% Parse VOC2007 data:

AdaptVOC2007Data(originalVOCDirectory,imgListDir,parsedVOCDir,params);

%% Compute proposals and individual detection rates:

ComputeProposals(parsedVOCDir, proposalsDir, configFile, evalParams);

%% Aggregate detection rates:

AggregateDRs(proposalsDir, parsedVOCDir, evalParams);

%% Compute Volume Under Surface:

nWindowsRange=[0 10000];
iouRange=[0.5 1];

nResults=numel(resultDirs);
drs=[];
for k=1:nResults
  data=load([resultDirs{k} '/aggregated_drs/drs.mat']);
  
  [cropped,legendStr]=CropEvaluations({data}, nWindowsRange, iouRange,{''});
  
  data=cropped{1};
  
  if(exist('ious','var'))
    assert( all(ious==data.ious));
  else
    ious=data.ious;
    nIous=length(ious);
  end
  
  if(exist('nWindows','var'))
    assert(all(nWindows==data.nWindows));
  else
    nWindows=data.nWindows;
    nnWindows=length(nWindows);
  end
  
  assert( ~exist('iNWindows','var') && ~exist('iIous','var'));
  
  drs=cat(3,drs,data.drs);
end

if(calcInLog)
  nWindows=log10(nWindows);
end

maxDrs=max(drs,[],3);
volumes=[];
maxVolume=trapz(ious, trapz(nWindows, maxDrs));
for k=1:nResults
  assert(all(all(maxDrs>=drs(:,:,k))));
  volumes=[ volumes, trapz(ious, trapz(nWindows, drs(:,:,k)))];
end

%Worse point computation
worsePoint=[];
for k=1:nResults
  worsePoint=[worsePoint, -max(max(maxDrs-drs(:,:,k)))];
end

perVolumes = volumes./((nWindows(end)-nWindows(1))*(ious(end)-ious(1)));

assert(all(perVolumes)>=0 && all(perVolumes)<=1);

volumeRatios=volumes/maxVolume;
[~, ids]=sort(volumeRatios,'descend');

volumeRatios=volumeRatios(ids);
worsePoint=worsePoint(ids);
perVolumes=perVolumes(ids);
assert(issorted(flipdim(perVolumes,2)));
for k=1:nResults
  fName=resultDirs{ids(k)};
  if(fName(end)=='/')
    fName=fName(1:(end-1));
  end
  [~,name,~]=fileparts(fName);
  disp('############################################################################');
  disp([ 'Volume Under Surface (VUS):' num2str(perVolumes(k))]);
end

%% Display DR curve:

selIou = 0.5;
semilogx(data.nWindows, data.drs(:, find(data.ious==selIou)), 'LineWidth', 3, 'Color', 'r');
ylim([0, 1]);
ylabel('Detection Rate');
xlabel('Number of proposals')
axis square;























