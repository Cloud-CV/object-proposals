% processCrfTrainImagesScript

basedir = ['/usr1/projects/GeometricContext/'];

imdir = [basedir 'images/all_images'];
outdir = [basedir 'data/crf/test'];


    
if 0
    load([basedir 'data/ijcv06/featureResultsSingle2.mat']);
    clear pg hacc vacc;
    load([basedir 'data/rand_indices.mat']);
    load([basedir 'data/allimsegs2.mat']);    
    load([basedir 'data/mcmcEdgeClassifier2.mat'])

end

fset{1} = [45:50 53:54 73:75]; % location
fset{2} = [1:14]; % color 
fset{3} = [15:44]; % texture
fset{4} = [51:52 57:72 76:94];  % vp

testind = cv_images;
for tf = 1:numel(testind)

    c = floor((tf-1)/50)+1;
    
    disp(num2str(tf))
    
    f = testind(tf);
    
    im = im2double(imread([imdir '/' imsegs(f).imname]));
    
    nsegments = [10 20 30 40 50 60 80 100];

    % if imsegs is a cell, it contains the system command to make the
    % segmentation image and the filename of the segmentation image

    spdata = mcmcGetSuperpixelData(im, imsegs(f)); 
    [edata, adjlist] = mcmcGetEdgeData(imsegs(f), spdata);
    imdata = mcmcComputeImageData(im, imsegs(f));
    
    pE = test_boosted_dt_mc(eclassifier, edata);
    pE = 1 ./ (1+exp(ecal{c}(1)*pE+ecal{c}(2)));

    smaps = generateMultipleSegmentations2(pE, adjlist, imsegs(f).nseg, nsegments);

    nsp = imsegs(f).nseg;  
    for ftype = 1:4
        pg{tf}{ftype} = zeros(nsp, 7);
    end

    segs = cell(nsp, 1);

    for k = 1:size(smaps, 2)

        for s = 1:max(smaps(:, k))

            [segs, ind] = checksegs(segs, smaps(:, k), s);            

            if ~isempty(ind)

                labdata = mcmcGetSegmentFeatures(imsegs(f), spdata, imdata, smaps(:, k), s);

                
                for ftype= 1:4
                
                    tmpdata = labdata(:, fset{ftype});
                    
                    vconf = test_boosted_dt_mc(vclassifier(ftype, c), tmpdata);
                    vconf = 1 ./ (1+exp(-vconf));
                    vconf = vconf / sum(vconf); 

                    hconf = test_boosted_dt_mc(hclassifier(ftype, c), tmpdata);
                    hconf = 1 ./ (1+exp(-hconf));
                    hconf = hconf / sum(hconf);            

                    sconf = test_boosted_dt_mc(sclassifier(ftype, c), tmpdata);
                    sconf = 1 ./ (1+exp(-sconf));           

                    pgs = [vconf(1) vconf(2)*hconf vconf(3)]*sconf;

                    pg{tf}{ftype}(ind, :) = pg{tf}{ftype}(ind, :) + repmat(pgs, numel(ind), 1);
                    
                end
                    
            end

        end

    end

    for ftype = 1:4
        pg{tf}{ftype} = pg{tf}{ftype} ./ ...
            max(repmat(sum(pg{tf}{ftype}, 2), 1, size(pg{tf}{ftype}, 2)), 0.00001); 
        cimages(ftype) = pg2confidenceImages(imsegs(f), pg{tf}(ftype));        
    end
    save([outdir '/' strtok(imsegs(f).imname, '.') '_c.mat'], 'cimages');
end
save([outdir '/multifeaturePg.mat'], 'pg');

   
   



