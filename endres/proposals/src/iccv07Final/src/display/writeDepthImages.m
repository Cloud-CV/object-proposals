function writeDepthImages(resdir, fn, outdir)

global DO_DISPLAY;
DO_DISPLAY = 0;

load '/home/dhoiem/src/cmu/iccv07Final/data/contactdt.mat';

for f = 1:numel(fn)
    
    disp(num2str(f))
    
    load([resdir strtok(fn{f}, '.') '_seg.mat']);
    
    [tmp, glabels] = max(bndinfo.result.geomProb, [], 2); 
    glabels((glabels>=2) & (glabels<=4)) = 2;
    glabels(glabels==5) = 3;
    
    lab = bndinfo.edges.boundaryType;
    
    lab = lab(1:end/2) + 2*lab(end/2+1:end);
    
    [imdepthMin, imdepthMax, imdepthCol, contact, x, y, z] = ...
        getDepthRangeForDisplay(bndinfo, glabels, lab, contactdt, 0.5);
   
    iptsetpref('ImshowBorder', 'tight');
    iptsetpref('ImtoolInitialMagnification', 100)    
    
    cmap = colormap('jet');    
    
    cmap = cmap(end:-1:1, :);
    
    set(gcf, 'PaperPositionMode', 'auto');
    outname = [outdir strtok(fn{f}, '.') '_depthMin.jpg'];
    figure(2), hold off, imshow(imdepthMin/5.3*64*4, cmap)
    print(['-f' num2str(2)], '-djpeg85', outname);    
    
    outname = [outdir strtok(fn{f}, '.') '_depthMax.jpg'];
    figure(3), hold off, imshow(imdepthMax/5.3*64*4, cmap)
    print(['-f' num2str(3)], '-djpeg85', outname);  

    tmp = imdepthCol;  tmp = tmp - min(tmp(:)); tmp = tmp / max(tmp(:));
    outname = [outdir strtok(fn{f}, '.') '_depthCol.jpg'];
    figure(3), hold off, imshow(tmp*64*4, cmap)
    print(['-f' num2str(3)], '-djpeg85', outname);     
    
    outname = [outdir strtok(fn{f}, '.') '_depthMean.jpg'];
    meanDepth = log((exp(imdepthMax)+exp(imdepthMin))/2);
    figure(4), hold off, imshow(meanDepth/5.3*64*4, cmap);
    print(['-f' num2str(4)], '-djpeg85', outname);
    
    stackDepth = cat(1, imdepthMin, imdepthMax);
    outname = [outdir strtok(fn{f}, '.') '_depthStacked.jpg'];
    figure(5), hold off, imshow(stackDepth/5.3*64*4, cmap);
    print(['-f' num2str(5)], '-djpeg85', outname);    
    
    outname = [outdir strtok(fn{f}, '.') '_contact.mat'];
    
    zmap = exp(meanDepth);
    save(outname, 'contact', 'x', 'y', 'z');
end