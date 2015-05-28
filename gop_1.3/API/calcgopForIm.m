function proposals=calcgopForIm(input, gopconfig )
    if ~isfield(gopconfig,'gopdatapath')
        fprintf('Path to GOP data does not exist. Please make sure you give a proper full path\n');
        return;
    else
        datapath=gopconfig.gopdatapath;
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
    max_iou=0.8;
    NumberOfSeeds=130;
    NumberOfSegmentationsPerSeed=4;
    method='baseline';
    if isfield(gopconfig.params,'detector')
        detector=gopconfig.params.detector;
    end
    if isfield(gopconfig.params,'max_iou')
        max_iou=gopconfig.params.max_iou;
    end
    if isfield(gopconfig.params,'NumberOfSeeds')
        NumberOfSeeds=gopconfig.params.NumberOfSeeds;
    end
    if isfield(gopconfig.params,'NumberOfSegmentationsPerSeed')
        NumberOfSegmentationsPerSeed=gopconfig.params.NumberOfSegmentationsPerSeed;
    end
    if isfield(gopconfig.params,'method')
        method=gopconfig.params.method;
    end
    % Set a boundary detector by calling (before creating an OverSegmentation!):
    gop_mex( 'setDetector', [detector '("'  datapath '/sf.dat")'] );

    if ( strcmp(method,'learned'))
        % Setup the proposal pipeline (learned)
        p = GopProposal('max_iou', max_iou,...
             'seed', [datapath '/seed_final.dat'],...
             'unary', NumberOfSeeds, NumberOfSegmentationsPerSeed, ['binaryLearnedUnary("' datapath '/masks_final_0_fg.dat")'], ['binaryLearnedUnary("' datapath '/masks_final_0_bg.dat")'],...
             'unary', NumberOfSeeds, NumberOfSegmentationsPerSeed, ['binaryLearnedUnary("' datapath '/masks_final_1_fg.dat")'], ['binaryLearnedUnary("' datapath '/masks_final_1_bg.dat")'],...
             'unary', NumberOfSeeds, NumberOfSegmentationsPerSeed, ['binaryLearnedUnary("' datapath '/masks_final_2_fg.dat")'], ['binaryLearnedUnary("' datapath '/masks_final_2_bg.dat")'],...
             'unary', 0, NumberOfSegmentationsPerSeed, 'zeroUnary()', 'backgroundUnary({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15})' ...
        );

    else
        % Setup the proposal pipeline (baseline)
        p = GopProposal('max_iou', max_iou,...
                     'unary', NumberOfSeeds, NumberOfSegmentationsPerSeed, 'seedUnary()', 'backgroundUnary({0,15})',...
                     'unary', 0, NumberOfSegmentationsPerSeed, 'zeroUnary()', 'backgroundUnary({0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15})' ...
                     );
    end
    os = GopOverSegmentation( im );
    props = p.propose( os );
    boxes = os.maskToBox( props );
    if(isfield(gopconfig.opts,'numProposals'))
            numProposals=gopconfig.opts.numProposals;
            if(size(boxes,1)>=numProposals)
                boxes=boxes(1:numProposals,:);
                else
                    fprintf('Only %d proposals were generated for the input image\n',size(boxes,1));
                end
    end
    proposals.boxes=boxes;
end


