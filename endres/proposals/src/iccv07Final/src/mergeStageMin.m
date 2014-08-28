function [result, pB] = mergeStageMin(X, bndinfo, dtBnd, dtFast, minRegions, thresh)
% result = mergeStageMin(X, bndinfo, dtBnd, minRegions)

global DO_DISPLAY;

if ~exist('thresh', 'var') || isempty(thresh)
    thresh = 0;
end

for f = 1:numel(X)

    if 0 && DO_DISPLAY
        disp(num2str(f))                         
        im = im2double(imread(['./iccvGroundTruth/images/' bndinfo(f).imname]));        
        gtim = drawBoundaries(im, bndinfo(f), bndinfo(f).edges.boundaryType);
        figure(2), imagesc(gtim), hold off, axis image        
    end   
    
    pB{f} = useBoundaryClassifier(bndinfo(f), X(f), dtBnd);
    pB{f} = [pB{f}(:, [1 2]) ; pB{f}(:, [1 3])];

    initnsp = bndinfo(f).nseg;
    
    result(f) = mergeMinSafe(pB{f}, bndinfo(f), X(f), dtFast, thresh, minRegions, 0);                 
    
    finalnsp = numel(result(f).regions);
    disp(['Regions: ' num2str(initnsp) ' --> ' num2str(finalnsp)]);
    
    
    if DO_DISPLAY
        pcim = zeros(size(bndinfo(f).wseg));   
        for k = 1:size(pB{f},1)/2
            pcim(bndinfo(f).edges.indices{k}) = 1-pB{f}(k, 1);
        end
        figure(3), imagesc(ordfilt2(pcim,9,ones(3))), axis image, colormap gray    
    end    
end


