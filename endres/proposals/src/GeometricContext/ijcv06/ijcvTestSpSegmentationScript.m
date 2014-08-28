% ijcvTestSegmentationScript

outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
imdir = '/IUS/vmr7/dhoiem/context/images/all_images';

if 0
    load '../data/mcmcSuperpixelClassifier.mat'
    load '../data/mcmcSuperpixelData.mat'
    load '../data/mcmcEdgeData.mat'
end

if ~exist('smaps') 

    for cvf = 1:numel(cv_images)

        disp(num2str(cvf))        
        
        f = cv_images(cvf);        
       
        % probability of superpixel main labels
        pvSP = test_boosted_dt_mc(vclassifierSP, spfeatures{f});
        pvSP = 1 ./ (1+exp(-pvSP));
        [tmp, vmax] = max(pvSP, [], 2);

        % probability of superpixel sub labels
        phSP = test_boosted_dt_mc(hclassifierSP, spfeatures{f});
        phSP = 1 ./ (1+exp(-phSP));
        [tmp, hmax] = max(phSP, [], 2);

        adjmat = zeros(size(imsegs(f).adjmat));
        for k = 1:size(adjlist{f},1)
            s1 = adjlist{f}(k, 1);
            s2 = adjlist{f}(k, 2);
            if (vmax(s1)==vmax(s2)) && (vmax(s1)~=2 || (hmax(s1)==hmax(s2)))
                adjmat(s1, s2) = 1;
                adjmat(s2, s1) = 1;
            end 
        end

        % get segments by connected components
        smaps{cvf} = graphComponents(adjmat);        
                     
        im = rgb2gray(im2double(imread([imdir '/' imsegs(f).imname])));
        bn = strtok(imsegs(f).imname, '.');

        outname = [outdir '/segmentations/' bn '.sp.jpg'];
        figure(1), 
        sim = imresize(displaySegments(smaps{cvf}, imsegs(f).segimage, im, 0), 0.5);
        figure(1), imagesc(sim), axis image, pause
        %sim = imresize(0.5*(im2double(label2rgb(smaps{cvf}(imsegs(f).segimage)))+im), 0.5);        
        imwrite(sim, outname);        

    end
    save([outdir '/spSegmentations.mat'], 'smaps');
end

if ~exist('segfeatures')
    segfeatures = mcmcGetAllSegmentFeatures(imsegs(cv_images), imdir, smaps, spfeatures(cv_images));
    for f = 1:numel(cv_images)
        [mclab{f}, mcprc{f}, allprc{f}, trainw{f}] = segmentation2labels(imsegs(cv_images(f)), smaps{f});
        trainw{f} = trainw{f}.*mcprc{f};
        %mclab{f} = mclab{f}.*(mcprc{f}>0.95);
    end
    save([outdir '/spSegFeatures2.mat'], 'segfeatures', 'mclab', 'mcprc', 'allprc', 'trainw');
end        
        
if ~exist('vclassifier')        
    disp('training segment classifiers')
    for k = 1:ncv
        testind = [((k-1)*numel(cv_images)/ncv+1):(k*numel(cv_images)/ncv)];
        trainind = setdiff([1:numel(cv_images)], testind);
        [vclassifier(k), hclassifier(k)] = ...
              mcmcTrainSegmentClassifier2(segfeatures(trainind), mclab(trainind), trainw(trainind), 50000);   
    end
end

%[vacc, hacc] = testSingleSegmentationsCV(imsegs(cv_images), segfeatures, smaps, vclassifier, hclassifier, ncv);
[vacc, hacc, vcm, hcm, pg] = testSingleSegmentationsCV(imsegs(cv_images), segfeatures, smaps, vclassifier, hclassifier, ncv);
segresults = testSegmentationConsistency(imsegs(cv_images), smaps);

save([outdir '/spSegResults2.mat'], 'vclassifier', 'hclassifier', 'vacc', 'hacc', 'vcm', 'hcm', 'pg', 'segresults');


