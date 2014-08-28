% processBoundaries

DO_OCCLUSION = 0;
DO_OCC_DEPTH = 0;
DO_OCC_MAPS = 0;
DO_OCC_GC = 0;
DO_PB = 1;
DO_PB2 = 0;
DO_UCM = 0;

dataset = 'tmp';
basedir = '/home/dhoiem/data/occlusion/tmp/';
imdir = '/home/dhoiem/data/occlusion/tmp/images';

if strcmp(dataset, 'bsds')
    imdir = '/home/dhoiem/data/occlusion/bsds/images/all';
    basedir = '/home/dhoiem/data/occlusion/bsds/';    
elseif strcmp(dataset, 'labelme')
    imdir = '/home/dhoiem/data/occlusion/labelme/test/Images';
    basedir = '/home/dhoiem/data/occlusion/labelme/';
end
filestr = '*.jpg';

maxsize = 800;
maxsize_pb2 =  800;

if DO_OCCLUSION      
    tocc = clock;
    addpath('/home/dhoiem/src/util/bsds/segbench/lib/matlab');
    %rmpath('/home/dhoiem/src/segmentation/BSDS/segbench/lib/matlab');
    outdir = [basedir 'occlusion'];   
    processDirectory(imdir, filestr, outdir, '_occlusion.mat', ...
        @processIm2Occlusion, maxsize);     
    rmpath('/home/dhoiem/src/util/bsds/segbench/lib/matlab');
    tocc=etime(clock, tocc);
   %addpath('/home/dhoiem/src/segmentation/BSDS/segbench/lib/matlab');
end

if DO_OCC_MAPS
    occdir = [basedir 'occlusion'];
    mapdir = [basedir 'occlusion'];
    
    fn = dir(fullfile(occdir, '*.mat'));
    fn = {fn.name};     
    for f = 1:numel(fn)
        id = strtok(fn{f}, '_occlusion');
        if ~exist(fullfile(mapdir, [id '_occmap.mat']), 'file')
            system(['touch ' fullfile(mapdir, [id '_occmap.mat'])]);
        
            load(fullfile(occdir, fn{f}));
            [po, pl, pr, mapo] = combineOcclusionMaps(bndinfo_all, pbim);                        
            po_all = getOcclusionMaps(bndinfo_all);            
            pb = pbim; %max(pbim, [], 3);
            
            save(fullfile(mapdir, [id '_occmap.mat']), 'po', 'pb', 'pl', 'pr', 'po_all');
        end
        
    end    
end
    
if DO_OCC_GC
    occdir = [basedir 'occlusion'];
    gcdir = [basedir 'geomcontext'];
  
    fn = dir(fullfile(occdir, '*.mat'));
    fn = {fn.name};    
    for f = 1:numel(fn)
        disp(num2str(f))
        id = strtok(fn{f}, '_occlusion');     
        if ~exist(fullfile(gcdir, [id '_gc.mat']), 'file')
            system(['touch ' fullfile(gcdir, [id '_gc.mat'])]);            
            load(fullfile(occdir, fn{f}));
            save(fullfile(gcdir, [id '_gc.mat']), 'gconf');
        end
    end
end
  
if DO_OCC_DEPTH
    occdir = [basedir 'occlusion'];
    depthdir = [basedir 'occlusion'];
    
    fn = dir(fullfile(occdir, '*.mat'));
    fn = {fn.name};    
    for f = 1:numel(fn)
        disp(num2str(f))
        id = strtok(fn{f}, '_occlusion');        
        if ~exist(fullfile(depthdir, [id '_occdepth.mat']), 'file')
            system(['touch ' fullfile(depthdir, [id '_occdepth.mat'])]);                
            [imd1, imd2, imd3] = occ2depth(bndinfo);
            save(fullfile(depthdir, [id '_occdepth.mat']), 'imd1', 'imd2', 'imd3');
        end        
    end
end

if DO_PB
    tic
    t_pb = clock;
    outdir = [basedir 'pb'];   
    processDirectory(imdir, filestr, outdir, '_pb.mat', ...
        @processIm2Pb, maxsize);  
    t_pb = etime(clock, t_pb);
    toc
end

if DO_PB2
    tpb2 = clock;
    outdir = [basedir 'pb2'];   
    processDirectory(imdir, filestr, outdir, '_pb2.mat', ...
        @processIm2Pb2, maxsize_pb2);     
    tpb2= etime(clock, tpb2);
end
disp(['time_occ = ' num2str(tocc) '  time_pb2 = ' num2str(tpb2)  '  time_pb = ' num2str(t_pb)]);
if DO_UCM
    outdir = [basedir 'pb'];   
    processDirectory(outdir, '*_pb.mat', outdir, '_ucm.mat', ...
        @processPb2Ucm);  
    outdir = [basedir 'pb2'];   
    processDirectory(outdir, '*_pb2.mat', outdir, '_ucm.mat', ...
       @processPb2Ucm);            
end








