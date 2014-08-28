function iccvWriteContourDepthResults

fn = {'college11', 'college12', 'college13', 'flat04', 'dirt01', 'dirt02', 'dirt09', ...
    'city08', 'buildings02', 'alley03', 'alley07', 'fields06', 'house01', 'structure12', ...
    'structure19', 'walking05', 'city02', 'cliff09', 'college06', 'dirt04', 'fields05', ...
    'house05', 'lawn02', 'outdoor2', 'outdoor5', 'outdoor7', 'outdoor9', 'outdoor18', ...
    'outdoor21', 'outdoor24', 'outdoor31','outdoor36','outdoor38','outdoor40','outdoor42',...
    'outdoor43','outdoor44','outdoor48','outdoor49','outdoor66','outdoor68','outdoor77', ...
    'roads08', 'rocks03', 'scenery15', 'structure5', 'structure15', 'structure16', ...
    'urban1', 'urban9', 'city01'};

resdir = './data4/smallsegs/3/';
outdir = './results/qualitative/';
imdir = './iccvGroundTruth/images/';
gtdir = './iccvGroundTruth/gtsave/';

%writeDepthImages(resdir, fn, outdir);

imdir =  '/home/dhoiem/cmu/GeometricContext/images/all_images/';
fn = {'structure19.jpg'};
outdir = './figs/';
gtdir = '~/src/cmu/iccv07/iccvGroundTruth/gtsave/';

for f = 1:numel(fn)
    
    bn = strtok(fn{f}, '.');
    
    im = im2double(imread([imdir bn '.jpg']));
    
    if 1 
    if exist([gtdir bn '_gt.mat'], 'file')
        load([gtdir bn '_gt.mat']);
        outname = [outdir bn '_gt.jpg'];

        contact = cell(bndinfo.nseg, 1);
%        wseg = bndinfo.labels(bndinfo.wseg);
        
        [bndinfo2, err] = updateBoundaryInfo2(bndinfo, bndinfo.labels);       
%        tmp = transferSuperpixelLabels(bndinfo, bndinfo2.wseg);        
        bndinfo2.names = bndinfo.names;
        bndinfo2.type = bndinfo.type;         
        bndinfo2 = orderfields(bndinfo2);                 
        
        bndinfo2 = processGtBoundaryLabels(bndinfo2);                        
        
        lab = bndinfo2.edges.boundaryType;
        lab = (lab(1:end/2)>0) + 2*(lab(end/2+1:end)>0);         
        
        printOcclusionResultWithContact(rgb2gray(im), bndinfo2, lab, outname, contact, 1);
    end
    end
    
    if 0 
    
    
    
    load([resdir bn '_seg.mat']);
    load([outdir bn '_contact.mat']);
    
    lab = bndinfo.edges.boundaryType;
    lab = lab(1:end/2) + 2*lab(end/2+1:end);
    
    outname = [outdir bn '_contour.jpg'];
    printOcclusionResultWithContact(im, bndinfo, lab, outname, contact, 1);
    end
end