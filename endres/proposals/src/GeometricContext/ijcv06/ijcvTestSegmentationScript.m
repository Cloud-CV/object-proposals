% ijcvTestSegmentationScript

nsegments = [3 6 12 25 50 100 200];

outdir = '/IUS/vmr20/dhoiem/data/ijcv06';
imdir = '/usr1/projects/dhoiem/GeometricContext/images/all_images';

if ~exist('smaps')
    %smaps =cell(numel(cv_images), numel(nsegments), 3);
    for cvf = 1:numel(cv_images)

        disp(num2str(cvf))        
        
        f = cv_images(cvf);
        c = ceil(cvf / 50);
       
        im = repmat(rgb2gray(im2double(imread([imdir '/' imsegs(f).imname]))), [1 1 3]);
        bn = strtok(imsegs(f).imname, '.');

        pE{f} = test_boosted_dt_mc(eclassifier, efeatures{f});
        pE{f} = 1 ./ (1+exp(ecal{c}(1)*pE{f} + ecal{c}(2)));

        for k = 1:numel(nsegments)
            kstr = num2str(1000+nsegments(k));                
            for j = 1:size(smaps, 3)
                smaps{cvf,k,j} = generateMultipleSegmentations2(pE{f}, adjlist{f}, imsegs(f).nseg, nsegments(k));

                outname = [outdir '/segmentations/' bn '.' kstr(2:end) '.' num2str(j) '.jpg'];
                sim = imresize(0.5*(im2double(label2rgb(smaps{cvf,k,j}(imsegs(f).segimage), 'jet'))+im), 0.5);
                imwrite(sim, outname);
            end   
        end
    end
    save([outdir '/singleSegmentations.mat'], 'smaps');
end

if ~exist('segfeatures')
    for k = 1:numel(nsegments)
        for j = 1:size(smaps, 3)
            segfeatures{k,j} = mcmcGetAllSegmentFeatures(imsegs(cv_images), imdir, smaps(:, k, j), spfeatures(cv_images));            
            for f = 1:numel(cv_images)
                [mclab{f, k, j}, mcprc{f, k, j}, allprc{f, k, j}, trainw{f, k, j}] = ...
                    segmentation2labels(imsegs(cv_images(f)), smaps{f,k,j});
                trainw{f,k,j} = trainw{f,k,j}.*mcprc{f,k,j};
                seglabel{f,k,j} =  (mcprc{f, k, j}>0.99);
                mclab{f,k,j} = mclab{f,k,j}.*(mcprc{f,k,j}>0.95);
            end
        end
    end
    save([outdir '/singleSegFeatures'], 'segfeatures', 'trainw', 'seglabel', 'mclab');
end        
        
if ~exist('vclassifier') || 1
    disp('training and testing segment classifiers')
    if 0
    for f = 1:numel(cv_images)
        for k = 1:numel(nsegments)
            for j = 1:size(smaps, 3)
                mclab{f,k,j} = mclab{f,k,j}.*(mcprc{f,k,j}>0.95);
            end
        end
    end
    end
    for k = 1:numel(nsegments)        
        for cv = 1:ncv
            disp(['iteration ' num2str(cv)])
            testind = [(cv-1)*50+1:cv*50];
            trainind = setdiff(1:numel(cv_images), testind);
            
            trainfeatures = [];
            trainlabels = [];
            trainweights = [];
            for j = 1:size(segfeatures, 2)
                trainfeatures = [trainfeatures ; segfeatures{k, j}(trainind)'];
                trainweights = [trainweights ; trainw(trainind, k, j) ];
                trainlabels = [trainlabels ; mclab(trainind, k, j)];
            end

            [vclassifier(cv, k), hclassifier(cv, k)] = ...
                mcmcTrainSegmentClassifier2(trainfeatures, trainlabels, trainweights, 50000);        
        end                  
        
        for j = 1:size(segfeatures, 2)
            [vacc(k,j), hacc(k,j)] = testSingleSegmentationsCV(...
                imsegs(cv_images), segfeatures{k,j}, smaps(:, k, j), vclassifier(:, k), hclassifier(:, k), ncv);
            segresults(k, j) = testSegmentationConsistency(imsegs(cv_images), smaps(:, k, j));
        end 
        
    end
end

save([outdir '/singleSegResults.mat'], 'vacc', 'hacc', 'segresults', 'vclassifier', 'hclassifier');
