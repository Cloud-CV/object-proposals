function ComputeProposals(parsedVOCDir, proposalsDir, configFile, evaluationParams)

  if(exist(proposalsDir, 'dir') ~= 0)
    disp(['The proposals dir: ' proposalsDir ' already exists. Press any key to use it (or delete it to parse it again)...']);
    pause;
    return;
  end
  
  f = dir(parsedVOCDir);
  f = f(3 : end);
  nImages = (numel(f) - 2) / 2; %Two additional files removed
  assert(nImages == round(nImages));
  mkdir(proposalsDir);
  
  configParams = LoadConfigFile(configFile);
  configParams.approxFinalNBoxes = 100000; %To increase number of unique windows and get the final part of the curve up to 10000.
  configParams.evaluationParams = evaluationParams;
  
  imgs = {};
  gts = {};
  % It is recommended to parallelize this loop to process and evaluate the
  % images in parallel:
  for k = 1 : nImages
    I = load([parsedVOCDir '/rgb_' num2str(k) '.mat']);
    imgs{end + 1} = I.iData.RGB;
    gt = load([parsedVOCDir '/gt_' num2str(k) '.mat']);
    gts{end + 1} = gt.gt;
    
    results = RPandEval(configParams, imgs{end}, gts{end});
    
    save([proposalsDir '/res_' num2str(k) '.mat'], 'results');
  end
end

function out = RPandEval(configParams, I, gt)
  out.proposals = RP(I, configParams);
  
  gt.gt.boxes = gt.boxes;
  
  out.drs = ComputeDR(out.proposals, gt, configParams.evaluationParams);
  out.ious = configParams.evaluationParams.ious;
  out.nWindows = configParams.evaluationParams.nWindows;
end





















