% ijcvSaSegs2MsScript

if 0
    load '../data/allimsegs2.mat'
    load '../data/rand_indices.mat'
    load '../data/mcmcEdgeClassifier.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcEdgeData.mat'    
    load '/IUS/vmr20/dhoiem/data/ijcv06/saResults2.mat'
end

imdir = '../images/all_images';
outdir = '/IUS/vmr20/dhoiem/data/ijcv06';

tmp = load('/IUS/vmr20/dhoiem/data/ijcv06/multisegResults2.mat');
vclassifier = tmp.vclassifier;
hclassifier = tmp.hclassifier;
sclassifier = tmp.sclassifier2;

for cf = 1:numel(cv_images)
    c = ceil(cf/50);
   
    disp([num2str(cf)]);
    
    f = cv_images(cf);
    
    im = im2double(imread([imdir '/' imsegs(f).imname]));
    imdata = mcmcComputeImageData(im, imsegs(f));
    
    [pvSP, phSP, pE] = mcmcInitialize(spfeatures{f}, efeatures{f}, ...
        adjlist{f}, imsegs(f), vclassifierSP, hclassifierSP, eclassifier, ecal{c}, 'none');
    
    pg{cf} = zeros(imsegs(f).nseg, 7);
    
    for i = 1:numel(segs2{cf})
        for j = 1:numel(segs2{cf}{i})
            sind = segs2{cf}{i}{j};
            map = zeros(imsegs(f).nseg, 1);
            map(sind) = 1;
            labdata = mcmcGetSegmentFeatures(imsegs(f), spfeatures{f}, imdata, map, 1);
            
            %segdata = mcmcGetSegmentationFeatures(pvSP, phSP, pE, adjlist{f}, imsegs(f).npixels, map, 1);
                        
            vconf = test_boosted_dt_mc(vclassifier(c), labdata);
            vconf = 1 ./ (1+exp(-vconf));
            vconf = vconf / sum(vconf);    

            hconf = test_boosted_dt_mc(hclassifier(c), labdata);
            hconf = 1 ./ (1+exp(-hconf));
            hconf = hconf / sum(hconf);     
        
            sconf = test_boosted_dt_mc(sclassifier(c), labdata);
            sconf = 1 ./ (1+exp(-sconf));
            sconf = sconf / sum(sconf);             
            
            pgs = [vconf(1) vconf(2)*hconf vconf(3)]*sconf;    
            
            pg{cf}(sind, :) = pg{cf}(sind, :) + repmat(pgs, [numel(sind) 1]);
        end
    end
    
    pg{cf} = pg{cf} ./ repmat(sum(pg{cf}, 2), [1 size(pg{cf}, 2)]);

end

[vacc, hacc, vcm, hcm] = mcmcProcessResult(imsegs(cv_images), pg);

save '/IUS/vmr20/dhoiem/data/ijcv06/saMsResults.mat' 'vacc' 'hacc' 'vcm' 'hcm' 'segs2' 'pg'
