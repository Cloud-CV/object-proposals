indir = '/IUS/vmr20/dhoiem/data/ijcv06';

tmp = load([indir '/multisegResults2.mat']);
pg = tmp.pg2;

for f = 1:numel(pg)
    [vacc(f), hacc(f)] = mcmcProcessResult(imsegs(cv_images(f)), pg(f));
end

[vacc, ind] = sort(vacc, 'ascend');
fn = {imsegs(cv_images).imname};
fn = fn(ind);
hacc = hacc(ind);

if 0
tmp = load([indir '/featureResultsSingle2.mat']);
pg = tmp.pg;

for k = 1:numel(pg)
    for f = 1:numel(pg{k})
        [vaccf{k}(f), haccf{k}(f)] = mcmcProcessResult(imsegs(cv_images(f)), pg{k}(f));
    end
    
%     [vaccf{k}, ind] = sort(vaccf{k}, 'ascend');
%     fnf{k} = {imsegs(cv_images).imname};
%     fnf{k} = fnf{k}(ind);
%     haccf{k} = haccf{k}(ind);
    
end
end
