function proposals=calclpoForIm(input, lpoconfig )
    if ~isfield(lpoconfig,'path')
        fprintf('Path to LPO does not exist. Please make sure you give a proper full path\n');
        return;
    else
        datapath=[lpoconfig.path, '/data/'];
        modelpath=[lpoconfig.path, '/models/'];
    end
    if(isstr(input))
        im = im2uint8(imread(input));
    else
        im = im2uint8(input); % Just to make input consistent
    end
    if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
    end
    model=[modelpath, 'lpo_VOC_0.1.dat'];
    detector='MultiScaleStructuredForest';
    max_iou=0.9;
    if isfield(lpoconfig.params,'model')
        model=[modelpath, lpoconfig.params.model];
    end
    if isfield(lpoconfig.params,'detector')
        detector=lpoconfig.params.detector;
    end
    if isfield(lpoconfig.params,'max_iou')
        max_iou=lpoconfig.params.max_iou;
    end
    % Set a boundary detector by calling (before creating an OverSegmentation!):
    lpo_mex( 'setDetector', [detector '("'  datapath 'sf.dat")'] );

    p = LpoProposal( 'model', model, 'box_nms', 'max_iou', max_iou );
    os = LpoOverSegmentation( im );
    [segs,props] = p.propose( os );
    boxes = masksToBoxes( segs, props );
    if(isfield(lpoconfig.opts,'numProposals'))
        numProposals=lpoconfig.opts.numProposals;
        if(size(boxes,1)>=numProposals)
            boxes=boxes(1:numProposals,:);
        else
            fprintf('Only %d proposals were generated for the input image\n',size(boxes,1));
        end
    end
    proposals.boxes=boxes;
end


