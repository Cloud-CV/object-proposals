% trainTestScript

DO_TRAIN = 0;
DO_BSDS_BOUNDARY_TEST = 0;
DO_LM_BOUNDARY_TEST = 0;
DO_LM_BOUNDARY_RESULTS = 0;
DO_LM_REGION_TEST = 0;
DO_REGION_TEST = 0;
DO_PASCAL08_REGION_TEST = 1;

setOcclusionDirectories;
alg = 'occ';  % occ_only, full_model, occ_only2

resultdir = fullfile(basedir, 'results', 'color', alg);

classifierfn = fullfile(traindir, ['boundaryClassifier_' alg]);


%% Training
if DO_TRAIN
    load(fullfile(traindir, 'trainData.mat'), 'x', 'y', 'featDescription');    
    if iscell(x)  
        x = cat(1, x{:});  y = cat(1, y{:});
    end
    if any(y==-1)
        x = x(y~=0, :);
        y = y(y~=0);
    end
    x = sparse(x);    
    w = trainBoundaryClassifier(x(1:10:end, 1:5), y(1:10:end));
    save(classifierfn, 'w');
end

%% BSDS Testing

if DO_BSDS_BOUNDARY_TEST    
    
    for a = {'pb2', 'ucm', 'ucm2'}
    alg = a{1};
    disp(alg);
    resultdir = fullfile(basedir, 'results', 'color', alg);
    clear pr_bsds    
    
    %load(fullfile(gtdir, 'tranferredBoundaryLabels.mat'), 'edgemap');
    load(fullfile(gtdir, 'trainTestFn.mat'), 'test', 'imfn');
    testids = load([bsdsdir 'iids_test.txt']);
    if ~exist(resultdir, 'file'), try, mkdir(resultdir); catch; end; end
    for k = 1:numel(test)

        iid = testids(k);               
                
        %pb = load(fullfile(pbdir, [num2str(iid) '_pb']));
        %pb2 = load(fullfile(pb2dir, [num2str(iid) '_pb2']));

        if strcmp(alg, 'occw')
            load(classifierfn, 'w');
            load(fullfile(gtdir, 'tranferredBoundaryLabels.mat'), 'edgemap');
            occ = load(fullfile(occdir, [num2str(iid) '_occmap']));
            ind = find(edgemap{test(k)});
            [x, featDescription] = getBoundaryFeatures(ind, occ); %, pb, pb2);
            %[x, featDescription] = getBoundaryEdgletFeatures(bndinfo_all,occ);        
            p = getBoundaryLikelihood(x(:, 1:5), w);
            bmap = zeros(size(occ.po));
            bmap(ind) = p;                            
        elseif strcmp(alg, 'occave')
            load(fullfile(occdir, [num2str(iid) '_occlusion']), 'bndinfo_all');
            occ.po_all = getOcclusionMaps(bndinfo_all);             
            bmap = mean(occ.po_all, 3);          
        elseif strcmp(alg, 'occ1')
            load(fullfile(occdir, [num2str(iid) '_occlusion']), 'bndinfo_all');
            occ.po_all = getOcclusionMaps(bndinfo_all);             
            bmap = occ.po_all(:, :, 1);                                  
        elseif strcmp(alg, 'pb')
            load(fullfile(pbdir, [num2str(iid) '_pb']), 'pb');
            bmap = pb;
        elseif strcmp(alg, 'pb2')
            load(fullfile(pb2dir, [num2str(iid) '_pb2']), 'pb');
            bmap = pb;            
        elseif strcmp(alg, 'ucm2')
            load(fullfile(pb2dir, [num2str(iid) '_pb2_ucm']), 'ucm');
            bmap = im2single(ucm);              
        elseif strcmp(alg, 'ucm')
            load(fullfile(pbdir, [num2str(iid) '_pb_ucm']), 'ucm');
            bmap = im2single(ucm);   
        end
    
        [segs,uids] = readSegs('color', iid);
        npts = 100;      
        [pr_bsds(k).p, pr_bsds(k).r, pr_bdsd(k).thresh] = getBoundaryPR(bmap, segs, 0.01, npts);
        pr_bsds(k).ap = averagePrecision(pr_bsds(k), (0:0.01:1));                    
        pr_bsds(k).f = fmeasure(pr_bsds(k).r, pr_bsds(k).p);  
        disp([num2str(k) ' : ' num2str([pr_bsds(k).ap mean([pr_bsds.ap])])]);
        
        im = imread(fullfile(imdir, [num2str(iid) '.jpg']));
        %figure(1), imagesc(im), axis image
        %figure(2), imagesc(bmap), axis image, colormap gray
        save(fullfile(resultdir, ['bsds_' alg '_pr']), 'pr_bsds'); 
        imwrite(bmap, fullfile(resultdir, [num2str(iid) '.bmp']));
    end    
    benchNewAlg(fullfile(basedir, 'results'),'color', alg);
    %boundaryBench(resultdir,'color', 25, 1);
    %boundaryBenchGraphs(resultdir);
    
    end % end for alg
end



if DO_REGION_TEST
    
    load(fullfile(gtdir, 'trainTestFn.mat'), 'test', 'imfn');
    testids = load([bsdsdir 'iids_test.txt']);
    alg = 'occ1';
    bestCovering = zeros(numel(testids), 1);
    for k = 1:numel(testids)

        iid = testids(k);
        imname = [num2str(iid) '.jpg'];
        
        
        occ = load(fullfile('~/data/occlusion/bsds/occlusion/', [num2str(iid) '_occlusion.mat']));
        niter = 1;
        maxov = 0.9;
        nr = []; % return all regions
        [regions, scores] = bndinfo2regions(occ.bndinfo_all{1}, imname, niter, maxov, nr);
             
        % compute covering
        [segs,uids] = readSegs('color', iid);
        tmpc = zeros(numel(segs), 1);
        for s = 1:numel(segs)
            tmpc(s) = getBestCovering(segs{s}, regions, occ.bndinfo_all{1}.wseg, true);
        end
        bestCovering(k) = mean(tmpc);
                
        disp(num2str([k bestCovering(k)]));
        
        %disp(num2str([bestCovering(k) mean(bestCovering(1:k))]));
        
    end

    save(fullfile(resultdir, 'covering.mat'), 'bestCovering');
    
end 

%% LabelMe Testing     

if DO_LM_BOUNDARY_TEST
    set = 'test';
    load(classifierfn, 'w');
    load(fullfile(basedir, [set '_db']));
    imdir = fullfile(basedir, set, 'Images');
    ap_occ1 = zeros(numel(db), 1);
    ap_occave = zeros(numel(db), 1);
    ap_occmax = zeros(numel(db), 1);
    ap_occw = zeros(numel(db), 1);
    %ap_pb2 = zeros(numel(db), 1);
    
    for k = 1:numel(db)
        
        folder = db(k).annotation.folder;
        bn = strtok(db(k).annotation.filename, '.');
        
        load(fullfile(occdir, folder, [bn '_occlusion']), 'bndinfo_all');
        occ.po_all = getOcclusionMaps(bndinfo_all);
        
        [x, featDescription] = getBoundaryEdgletFeatures(bndinfo_all,occ);

        p = getBoundaryLikelihood(x, w);

        occmap = zeros([size(occ.po_all,1) size(occ.po_all,2)], 'single');
        indices = bndinfo_all{1}.edges.indices;
        for e = 1:numel(indices)           
            occmap(indices{e}) = p(e);
        end
        save(fullfile(occdir, folder, [bn '_occw']), 'occmap');
        
        outfolder = fullfile(basedir, 'results', folder);
        if ~exist(outfolder, 'file'), mkdir(outfolder); end
        imwrite(occmap, fullfile(outfolder, [bn '_occ.jpg']), 'Quality', 95);
        
        %load(fullfile(basedir, 'pb2', folder, [bn '_pb2']), 'pb');
        %imwrite(pb, fullfile(outfolder, [bn '_pb2.jpg']), 'Quality', 95);
        if 0
        im = imread(fullfile(imdir, folder, [bn '.jpg']));
        im = imresize(im2double(im), size(occmap), 'bilinear');
        bndim = repmat(rgb2gray(im)*0.5+0.5, [1 1 3]);
        npix = numel(occmap);
        occmap2 = ordfilt2(occmap, 9, ones(3,3));
        ind = find(occmap2>0.05);  bndim(ind) = occmap2(ind); bndim([npix+ind ; npix*2+ind]) = 0;
        %ind = find(pb2>0);  bndim(ind + npix) = pb(ind); bndim([ind ; npix*2+ind]) = 0;        
        figure(1), imagesc(bndim), axis image                
        
        load(fullfile(gtdir, folder, [bn '_labels']), 'lim');
        [pr.p, pr.r] = getBoundaryPR(occmap, {lim}, 0.01, 100);
        ap_occw(k) = averagePrecision(pr, (0:0.01:1));
        %[pr.p, pr.r] = getBoundaryPR(pb, {lim}, 0.01, 100);
        %ap_pb2(k) = averagePrecision(pr, (0:0.01:1)); 
        [pr.p, pr.r] = getBoundaryPR(mean(occ.po_all, 3), {lim}, 0.01, 100);
        ap_occave(k) = averagePrecision(pr, (0:0.01:1));                
        [pr.p, pr.r] = getBoundaryPR(occ.po_all(:, :, 1), {lim}, 0.01, 100);
        ap_occ1(k) = averagePrecision(pr, (0:0.01:1));                
        [pr.p, pr.r] = getBoundaryPR(max(occ.po_all, [], 3), {lim}, 0.01, 100);        
        ap_occmax(k) = averagePrecision(pr, (0:0.01:1));                
        tmp = [ap_occw ap_occ1 ap_occave ap_occmax];
        disp(num2str(mean(tmp(1:k, :), 1)))
        drawnow;
        end
    end
    %save(fullfile(basedir, 'results', 'result_LM_ap_occ'), 'ap_occw', 'ap_occave', 'ap_occ1', 'ap_occmax');

    %boundaryBench(resultdir,'color', 25, 1);
    %boundaryBenchGraphs(resultdir);
end

if DO_LM_BOUNDARY_RESULTS
    set = 'test';
    
    npts = 100;
    
    DO_OCC = 0;
    DO_PB = 0;
    DO_PB2 = 0;
    DO_UCM = 0;
    DO_UCM1 = 1;
       
    %load(fullfile(basedir, [set '_db']));
    
    if DO_OCC
        pr_occw = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);
        pr_occ1 = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);    
        pr_occave = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);
        pr_occmax = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);              
    end
    
    if DO_PB2
        pr_pb2 = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);        
    end
    if DO_UCM
        pr_ucm = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);        
    end    
    if DO_UCM1
        pr_ucm1 = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);        
    end     
    if DO_PB
        pr_pb = repmat(struct('p', [], 'r', []', 'thresh', [], 'ap', [], 'f', []), numel(db), 1);        
    end
    
    for k = 1:numel(db)
        
        if mod(k, 50)==0
            disp(num2str(k));
        end
        
        folder = db(k).annotation.folder;
        bn = strtok(db(k).annotation.filename, '.');
        load(fullfile(gtdir, folder, [bn '_labels']), 'lim');
        
        if DO_OCC
            load(fullfile(occdir, folder, [bn '_occw']), 'occmap');        
            load(fullfile(occdir, folder, [bn '_occlusion']), 'bndinfo_all');
            occ.po_all = getOcclusionMaps(bndinfo_all);                            
                
            [pr_occw(k).p, pr_occw(k).r, pr_occw(k).thresh] = getBoundaryPR(occmap, {lim}, 0.01, npts);
            pr_occw(k).ap = averagePrecision(pr_occw(k), (0:0.01:1));
            pr_occw(k).f = fmeasure(pr_occw(k).r, pr_occw(k).p);
            [pr_occave(k).p, pr_occave(k).r, pr_occave(k).thresh] = getBoundaryPR(mean(occ.po_all, 3), {lim}, 0.01, npts);
            pr_occave(k).ap = averagePrecision(pr_occave(k), (0:0.01:1));                
            pr_occave(k).f = fmeasure(pr_occave(k).r, pr_occave(k).p);
            [pr_occ1(k).p, pr_occ1(k).r, pr_occ1(k).thresh] = getBoundaryPR(occ.po_all(:, :, 1), {lim}, 0.01, npts);
            pr_occ1(k).ap = averagePrecision(pr_occ1(k), (0:0.01:1));                
            pr_occ1(k).f = fmeasure(pr_occ1(k).r, pr_occ1(k).p);
            [pr_occmax(k).p, pr_occmax(k).r, pr_occave(k).thresh] = getBoundaryPR(max(occ.po_all, [], 3), {lim}, 0.01, npts);        
            pr_occmax(k).ap = averagePrecision(pr_occmax(k), (0:0.01:1));    
            pr_occmax(k).f = fmeasure(pr_occmax(k).r, pr_occmax(k).p);                        
        end
        
        if DO_PB2
            load(fullfile(basedir, 'pb2', folder, [bn '_pb2']), 'pb');
            [pr_pb2(k).p, pr_pb2(k).r, pr_pb2(k).thresh] = getBoundaryPR(pb, {lim}, 0.01, 100);
            pr_pb2(k).ap = averagePrecision(pr_pb2(k), (0:0.01:1));
            pr_pb2(k).f = fmeasure(pr_pb2(k).r, pr_pb2(k).p);            
        end
        
        if DO_UCM
            load(fullfile(basedir, 'pb2', folder, [bn '_pb2_ucm']), 'ucm');
            [pr_ucm(k).p, pr_ucm(k).r, pr_ucm(k).thresh] = getBoundaryPR(im2single(ucm), {lim}, 0.01, 100);
            pr_ucm(k).ap = averagePrecision(pr_ucm(k), (0:0.01:1));
            pr_ucm(k).f = fmeasure(pr_ucm(k).r, pr_ucm(k).p);            
        end  
        if DO_UCM1
            load(fullfile(basedir, 'pb', folder, [bn '_pb_ucm']), 'ucm');
            [pr_ucm1(k).p, pr_ucm1(k).r, pr_ucm1(k).thresh] = getBoundaryPR(im2single(ucm), {lim}, 0.01, 100);
            pr_ucm1(k).ap = averagePrecision(pr_ucm1(k), (0:0.01:1));
            pr_ucm1(k).f = fmeasure(pr_ucm1(k).r, pr_ucm1(k).p);            
        end                  
        if DO_PB
            load(fullfile(basedir, 'pb', folder, [bn '_pb']), 'pb');
            [pr_pb(k).p, pr_pb(k).r, pr_pb(k).thresh] = getBoundaryPR(pb, {lim}, 0.01, 100);
            pr_pb(k).ap = averagePrecision(pr_pb(k), (0:0.01:1));
            pr_pb(k).f = fmeasure(pr_pb(k).r, pr_pb(k).p);            
        end        
        %[pr.p, pr.r] = getBoundaryPR(pb, {lim}, 0.01, 100);
        %ap_pb2(k) = averagePrecision(pr, (0:0.01:1));         
        
    end    
    if DO_OCC
        save(fullfile(basedir, 'results', 'result_LM_pr_occ'), 'pr_occw', 'pr_occave', 'pr_occ1', 'pr_occmax');
    end
    if DO_PB2
        save(fullfile(basedir, 'results', 'result_LM_pb2_occ'), 'pr_pb2');
    end
    if DO_UCM
        save(fullfile(basedir, 'results', 'result_LM_ucm_occ'), 'pr_ucm');
    end    
    if DO_UCM1
        save(fullfile(basedir, 'results', 'result_LM_ucm1_occ'), 'pr_ucm1');
    end
    if DO_PB
        save(fullfile(basedir, 'results', 'result_LM_pb_occ'), 'pr_pb');
    end    
    %boundaryBench(resultdir,'color', 25, 1);
    %boundaryBenchGraphs(resultdir);
end
    
if DO_LM_REGION_TEST
    
    set = 'test';
    htype = 'mean';
    
    load(classifierfn, 'w');
    load(fullfile(basedir, [set '_db']));
    imdir = fullfile(basedir, set, 'Images');
    
    for k = 1:numel(db)

        folder = db(k).annotation.folder;
        bn = strtok(db(k).annotation.filename, '.');
        load(fullfile(gtdir, folder, [bn '_labels']), 'lim');
        
        load(fullfile(occdir, folder, [bn '_occlusion']), 'bndinfo_all');
        occ_pb = getOcclusionPb(bndinfo_all);
        lim = imresize(lim, bndinfo_all{1}.imsize, 'nearest');
        
        % occ1
        hier = boundaries2hierarchy(occ_pb(:, 1), bndinfo_all{1}.edges.spLR, htype);
        cover_occ1(k) = getBestCovering(lim, hier.regions, bndinfo_all{1}.wseg);
        
        % occave
        hier = boundaries2hierarchy(mean(occ_pb, 2), bndinfo_all{1}.edges.spLR, htype);
        cover_occave(k) = getBestCovering(lim, hier.regions, bndinfo_all{1}.wseg);
        
        % occw
        occ.po_all = getOcclusionMaps(bndinfo_all);        
        [x, featDescription] = getBoundaryEdgletFeatures(bndinfo_all,occ);
        pb = getBoundaryLikelihood(x, w);        
        hier = boundaries2hierarchy(pb, bndinfo_all{1}.edges.spLR, htype);
        cover_occw(k) = getBestCovering(lim, hier.regions, bndinfo_all{1}.wseg);        
        
        % occorig
        regions = getBndinfoRegions(bndinfo_all);
        cover_occorig(k) = getBestCovering(lim, regions, bndinfo_all{1}.wseg);  
        
        % ucm1
        load(fullfile(pbdir, folder, [bn '_pb_ucm']), 'ucm');
        bndinfo = ucm2bndinfo(ucm);
        hier = boundaries2hierarchy(bndinfo.pbnd, bndinfo.edges.spLR, htype);
        cover_ucm1(k) = getBestCovering(lim, hier.regions, bndinfo.wseg);      
        
        % ucm2
        load(fullfile(pb2dir, folder, [bn '_pb2_ucm']), 'ucm');
        bndinfo = ucm2bndinfo(ucm);
        hier = boundaries2hierarchy(bndinfo.pbnd, bndinfo.edges.spLR, htype);
        cover_ucm2(k) = getBestCovering(lim, hier.regions, bndinfo.wseg);             
        
        disp([num2str(k) ': pix = ' num2str(mean([[cover_occ1.pix]' [cover_occave.pix]' [cover_occw.pix]' [cover_occorig.pix]' [cover_ucm1.pix]'  [cover_ucm2.pix]'],1))]); 
        disp([num2str(k) ': unw = ' num2str(mean([[cover_occ1.unweighted]' [cover_occave.unweighted]' [cover_occw.unweighted]' [cover_occorig.unweighted]' [cover_ucm1.unweighted]'  [cover_ucm2.unweighted]'],1))]);        
        
    end

    save(fullfile(basedir, 'results', ['result_LM_region_' htype '_covering']), 'cover_occ1', 'cover_occave', 'cover_occw', 'cover_occorig', 'cover_ucm1', 'cover_ucm2');    
    
end 


if DO_PASCAL08_REGION_TEST
    
    htype = 'mean';
    
    basedir = '~/data/occlusion/pascal08/';
    files = dir([basedir 'images/*.jpg']);
    imfn = {files.name};
    
    for k = 1:numel(imfn)

        bn = strtok(imfn{k}, '.');
        load(fullfile(basedir, 'labels', [bn '_labels']), 'lim');
        
        load(fullfile(basedir, 'occlusion', [bn '_occlusion']), 'bndinfo_all');
        occ_pb = getOcclusionPb(bndinfo_all);
                
        % occ1
        hier = boundaries2hierarchy(occ_pb(:, 1), bndinfo_all{1}.edges.spLR, htype);
        bndinfo_all{1}.wseg(lim==-1) = 0;
        cover_occ1(k) = getBestCovering(lim, hier.regions, bndinfo_all{1}.wseg);
        
        % occave
        occ_ave = mean(pb, 2); % sum(occ_pb, 2) ./ sum(occ_pb>0, 2);
        hier = boundaries2hierarchy(occ_ave, bndinfo_all{1}.edges.spLR, htype);
        bndinfo_all{1}.wseg(lim==-1) = 0;
        cover_occave(k) = getBestCovering(lim, hier.regions, bndinfo_all{1}.wseg);        
        
%         % ucm1
%         load(fullfile(pbdir, folder, [bn '_pb_ucm']), 'ucm');            
%         bndinfo = ucm2bndinfo(ucm);
%         hier = boundaries2hierarchy(bndinfo.pbnd, bndinfo.edges.spLR, htype);
%         cover_ucm1(k) = getBestCovering(lim, hier.regions, bndinfo.wseg);      
%         
        % ucm2
        pb2dir = fullfile(basedir, 'pb2');
        load(fullfile(pb2dir, [bn '_pb2']), 'pb_all');
        ucm = contours2ucm(im2uint8(pb_all));
        bndinfo = ucm2bndinfo(ucm);
        bndinfo.wseg(lim==-1) = 0;
        hier = boundaries2hierarchy(bndinfo.pbnd, bndinfo.edges.spLR, htype);
        cover_ucm2(k) = getBestCovering(lim, hier.regions, bndinfo.wseg);             
        
        disp([num2str(k) ': pix = ' num2str(mean([[cover_occ1.pix]' [cover_occave.pix]'  [cover_ucm2.pix]'],1))]); 
        disp([num2str(k) ': unw = ' num2str(mean([[cover_occ1.unweighted]' [cover_occave.unweighted]'  [cover_ucm2.unweighted]'],1))]);        
        
    end

    save(fullfile(basedir, 'results', ['result_PAS08_region_' htype '_covering2']), 'cover_occ1', 'cover_occave', 'cover_ucm2');
    
end 
