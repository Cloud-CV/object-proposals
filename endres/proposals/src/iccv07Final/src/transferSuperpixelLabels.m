function [bndinfo2, err] = transferSuperpixelLabels(bndinfo, wseg2)

wseg1 = bndinfo.wseg;

labim = zeros(size(wseg1));
labim(wseg1>0) = bndinfo.labels(wseg1(wseg1>0));

stats = regionprops(wseg2, 'PixelIdxList');
spind = {stats(:).PixelIdxList};

lab2 = zeros(max(wseg2(:)), 1);

for k = 1:numel(lab2)
    pixlab = labim(spind{k});
    pixlab = pixlab(pixlab>0);
    if numel(pixlab)>numel(spind{k})*0.01
        lab2(k) = mode(pixlab);        
    end
end

bndinfo2 = bndinfo;
bndinfo2.wseg = uint16(wseg2);
bndinfo2.labels = lab2;

labim2 = zeros(size(wseg2));
labim2(wseg2>0) = bndinfo2.labels(wseg2(wseg2>0));

ind = (labim2 > 0) & (labim > 0);

if nargout > 1
    err = mean(labim(ind)~=labim2(ind));
    disp(num2str([max(wseg1(:)) max(wseg2(:))]))
    disp(['Error: ' num2str(err)]);
end
    