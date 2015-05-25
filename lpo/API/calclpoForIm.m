function proposals=calclpoForIm(input, lpoconfig )
    if ~isfield(lpoconfig,'lpodatapath')
        fprintf('Path to LPO data does not exist. Please make sure you give a proper full path\n');
        return;
    else
        datapath=lpoconfig.lpodatapath;
    end
    if(isstr(input))
        im = im2uint8(imread(input));
    else
        im = im2uint8(input); % Just to make input consistent
    end
    if(size(im, 3) == 1)
        im=repmat(im,[1,1,3]);
    end
    detector='MultiScaleStructuredForest';
    max_iou=0.9;
    if isfield(lpoconfig.params,'detector')
        detector=lpoconfig.params.detector;
    end
    if isfield(lpoconfig.params,'max_iou')
        max_iou=lpoconfig.params.max_iou;
    end
    % Set a boundary detector by calling (before creating an OverSegmentation!):
    lpo_mex( 'setDetector', [detector '("'  datapath '/sf.dat")'] );

    p = Proposal();
    os = OverSegmentation( im );
    props = p.propose( os );
    boxes = os.maskToBox( props );
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


