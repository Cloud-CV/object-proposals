function proposals = RP(rgbI, params)
% The Randomized Prim's algorithm (RP) takes as input an image and some
% parameters and returns object proposals as bounding boxes.
%
% Parameters:
%
%   - Input:
%     - rgbI: Input image. Must have 3 channels and be in RGB colorspace.
%     - params: Parameters to run RP. These can be loaded from
%     config/rp.mat or config/rp_4segs.mat
%
%   - Output:
%     - proposals: List of proposed bounding boxes, which are likely to
%     contain and properly fit objects in the image. The list is provided
%     as a matrix of N-by-4 elements, where N is the number of proposals.
%     Each row reperesents one proposal with the format [xmin, ymin, xmax,
%     ymax].

  %% Set random seed:
  if(params.rSeedForRun == -1)
    params.rSeedForRun = mod(sum(rgbI(:)),intmax());
  end
  rng(params.rSeedForRun);
  
  %% Compute proposals:
  nSegs=numel(params.segmentations);
  segBoxes = cell(nSegs, 1);
  for k = 1 : nSegs        
    mexParams = params.segmentations{k};
    mexParams.nProposals = params.approxFinalNBoxes / (nSegs * 0.8);
    if(isfield(params, 'rSeedForRun'))
      mexParams.rSeedForRun = params.rSeedForRun + k;
    end

    if(size(rgbI, 3) == 1)
      rgbI = repmat(rgbI, [1, 1, 3]);
    end
    
    % Run RP in mex file
    segBoxes{k} = RP_mex(rgbI, mexParams);
  end
  
  %% Sort proposals
  nBoxesPerSeg = size(segBoxes{k}, 1);
  for k = 1 : nSegs
    assert(size(segBoxes{k}, 1) == nBoxesPerSeg);
  end
  proposals = [];
  for k = 1 : nSegs
    proposals = [proposals, segBoxes{k}];
  end
  proposals = proposals';
  proposals = reshape(proposals, 4, []);
  proposals = proposals';
  
  %% Remove near duplicates:
  assert(params.q > 0)
  qBoxes = round(proposals(:, 1 : 4) / params.q);
  [~, ids] = unique(qBoxes, 'rows', 'first');
  [ids] = sort(ids, 'ascend');
  proposals = proposals(ids, :);
end
















