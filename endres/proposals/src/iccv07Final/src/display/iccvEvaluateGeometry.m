function [accgvs, accpps] = iccvEvaluateGeometry(imsegs)

resdir = './data4/smallsegs/3/';

totalgvs = 0;
accgvs = 0;

totalpps = 0;
accpps = 0;

for f = 1:numel(imsegs)
    fn = imsegs(f).imname;    
    load([resdir strtok(fn, '.') '_seg.mat']);
    
    gvsgt = imsegs(f).vert_labels(imsegs(f).segimage);
    ppsgt = imsegs(f).horz_labels(imsegs(f).segimage);
    ppsgt = (ppsgt<=3) + (ppsgt==4)*2 + (ppsgt==5)*3;
    
    pg = bndinfo.result.geomProb;
    gvspg = [pg(:, 1) sum(pg(:, 2:4),2) pg(:, 5)];
    ppspg = pg(:, 2:4);
    [tmp, gvsres] = max(gvspg, [], 2);
    [tmp, ppsres] = max(ppspg, [], 2);
    
    gvsres = gvsres(bndinfo.wseg);
    ppsres = ppsres(bndinfo.wseg);
    
    accgvs = accgvs + sum(gvsres(:)==gvsgt(:)) / sum(gvsgt(:)>0);
    totalgvs = totalgvs + mean(gvsgt(:)>0);
   
    accpps = accpps + sum(ppsres(:)==ppsgt(:)) / sum(ppsgt(:)>0);
    totalpps = totalpps + mean(ppsgt(:)>0);
    
    disp(num2str([accgvs/totalgvs accpps/totalpps]));
    
end

