function pbim = getPbImage(pB, bndinfo)
% pbim = getPbImage(pB, bndinfo)

pbim = zeros(size(bndinfo.wseg));   
for k = 1:numel(pB)
    pbim(bndinfo.edges.indices{k}) = pB(k);
end
figure(3), imagesc(ordfilt2(pbim,9,ones(3))), axis image, colormap gray    
