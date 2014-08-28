function plotValdata(valdata, fignum)


cthresh = (0.001:0.001:0.5);
err = zeros(size(cthresh));
nregions = zeros(size(cthresh));
for f = 1:numel(valdata)
    for k = 1:numel(cthresh)
        [tmp, minind] = min(abs(valdata(f).mergeCost-cthresh(k)));
        err(k) = err(k) + valdata(f).segError(minind)/numel(valdata);
        nregions(k) = nregions(k) + valdata(f).nregions(minind)/numel(valdata);
    end
end
figure(fignum), subplot(2,2,1), hold off, plot(cthresh, err), title('bias vs. err')
figure(fignum), subplot(2,2,2), plot(err, nregions), title('conf: err vs. nregions')

rthresh = (5:5:1000);
err = zeros(size(rthresh));
nregions = zeros(size(rthresh));
for f = 1:numel(valdata)
    for k = 1:numel(rthresh)
        [tmp, minind] = min(abs(valdata(f).nregions-rthresh(k)));
        err(k) = err(k) + valdata(f).segError(minind)/numel(valdata);
        nregions(k) = nregions(k) + valdata(f).nregions(minind)/numel(valdata);
    end
end
figure(fignum), subplot(2,2,3), plot(rthresh, err),  title('minregion vs. err')
figure(fignum), subplot(2,2,4), plot(err, nregions), title('minreg: err vs. nregions')