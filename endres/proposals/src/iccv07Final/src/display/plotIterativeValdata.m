function plotIterativeValdata(valdata, fignum)

cthresh = [valdata(1, :).cthresh];
err = zeros(size(cthresh));
nregions = zeros(size(cthresh));
for f = 1:size(valdata,1)
    for k = 1:numel(cthresh)        
        err(k) = err(k) + (1-valdata(f,k).conservation) / size(valdata,1);
        nregions(k) = nregions(k) + valdata(f,k).nregions / size(valdata,1);
    end
end
figure(fignum), subplot(1,2,1), hold off, plot(cthresh, err), title('thresh vs. err')
figure(fignum), subplot(1,2,2), plot(err, nregions), title('conf: err vs. nregions')
drawnow;
