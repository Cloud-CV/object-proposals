function printOcclusionResult(im, bndinfo, lab, fn, fignum)

if ~exist('fignum', 'var') || isempty(fignum)
    fignum = 1;
end

if isfield(bndinfo, 'labels')
    objlab = bndinfo.labels;
elseif isfield(bndinfo, 'result') && isfield(bndinfo.result, 'geomProb')
    objlab = zeros(bndinfo.nseg, 1);
    [maxval, maxlab] = max(bndinfo.result.geomProb, [], 2);
    ind = find(maxlab>=2 & maxlab<=4);    
    objlab(ind) = (3:2+numel(ind));
    objlab(maxlab==1) = 1;
    objlab(maxlab==5) = 2;    
else
    objlab = [];
end

displayOcclusionResult(im, bndinfo, objlab, lab, {}, fignum);
set(gcf, 'PaperPositionMode', 'auto');
%print(['-f' num2str(fignum)], '-djpeg99', fn); 
print(['-f' num2str(fignum)], '-depsc2', [fn(1:end-4) '.eps']); 