function bsdsAnalyzeResult(pb, imfn, outdir)


for f = 1:numel(pb)
    tmp = load(['~/data/eccv08/bsds/pb/' strtok(imfn{f}, '.') '_pb.mat']);
    pb{f} = bsdsNonMaxSuppression(pb{f}, tmp.pb);    
    imwrite(pb{f}, [outdir strtok(imfn{f}, '.') '.bmp']);
end

boundaryBench(outdir,'color', 25, 1)