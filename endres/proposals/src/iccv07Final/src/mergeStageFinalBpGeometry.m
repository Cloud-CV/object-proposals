function [bndinfo2, lab, plab_e, plab_g, bel1] = mergeStageFinalBpGeometry(...
    bndinfo, dtBnd, dtBnd_fast, dtCont, thresh, im, pbim, gconf, gdata, ...
    gclassifiers, segmaps, wseg_orig)
% [result, dispim] = mergeStage(X, bndinfo, dtBnd, thresh)
% bias sets the bias for turning an edge off (e.g., bias = 60% means that
% we want to be 60% confident that the edge is off)

 
gparams = [1.33 0.16];
bel1 = [];    
bndinfo2 = bndinfo;

while 1    

    X = getFeatures(bndinfo, im, pbim, gconf);
    [X, gdata] = updateGeometricFeatures(im, X, segmaps, gclassifiers, gdata, gparams);               
    
    initnsp = bndinfo.nseg;  
    [pB, bndx] = useBoundaryClassifier(bndinfo, X, dtBnd);
    pB = [pB(:, [1 2]) ; pB(:, [1 3])];
    if isempty(bel1)
        bel1 = pB;
    end
    
    [pC, adjlist] = getContinuityLikelihood(X, bndinfo, ...
             (1:bndinfo.ne*2), pB, dtCont, bndx);                                                            

    pg = X.region.geomContext;
    [factors, f2var] = getContourGeometryPotentials(pB, pC, adjlist, pg, bndinfo);
    nnodes = [3*ones(bndinfo.ne, 1) ; 5*ones(bndinfo.nseg, 1)];
    [mllab, bel] = maxBeliefPropBethe(factors, f2var, nnodes, 0.025, 0.5, Inf);
    ebel = cell2mat(bel(1:bndinfo.ne)')';          
    gbel = cell2mat(bel(bndinfo.ne+1:end)')';
    tmpbel = [ebel(:, 1:2) ; ebel(:, [1 3])];  

    result = mergeMinSafe(tmpbel, bndinfo, X, dtBnd_fast, thresh, 2, 0);               

    finalnsp = numel(result.regions);
    disp(['Regions: ' num2str(initnsp) ' --> ' num2str(finalnsp)]);                          

    if finalnsp==initnsp        
        lab = [(ebel(:, 2)>ebel(:, 3)) ; (ebel(:, 3) >= ebel(:, 2))];
        plab_e = ebel;                        
        plab_g = gbel;
        break;
    else
        bndinfo2 = updateBoundaryInfo(bndinfo, result, im);
        bndinfo = bndinfo2;
        
        bndinfotmp = bndinfo;
        bndinfotmp.labels = (1:bndinfo.nseg);
        bndinfotmp = transferSuperpixelLabels(bndinfotmp, wseg_orig);    
        segmaps = bndinfotmp.labels;        

    end
end
        
    