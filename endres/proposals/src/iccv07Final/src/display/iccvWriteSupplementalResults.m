function iccvWriteSupplementalResults(fn)

gtdir1 = './iccvGroundTruth/gtsave/';
ourdir1 = './data4/smallsegs/3/';
ncutdir1 = './data4/ncutsegs/';
geomdir1 = './data4/geomsegs/';

gtdir2 = './results/supp/gt/';
ourdir2 = './results/supp/result/';
ncutdir2 = './results/supp/ncut/';
geomdir2 = './results/supp/geom/';


imdir = './iccvGroundTruth/images/';

for f = 1:numel(fn)
    
    disp(num2str(f))
    
    bn = strtok(fn{f}, '.');
    
    im = im2double(imread([imdir bn '.jpg']));    
    
    %% gt
    if 0
    load([gtdir1 bn '_gt.mat']);
    outname = [gtdir2 bn '_gt.jpg'];

    contact = {}; %cell(bndinfo.nseg, 1);

    bndinfo2 = updateBoundaryInfo2(bndinfo, bndinfo.labels);       
       
    bndinfo2.names = bndinfo.names;
    bndinfo2.type = bndinfo.type;         
    bndinfo2 = orderfields(bndinfo2);                 

    bndinfo2 = processGtBoundaryLabels(bndinfo2);                        

    lab = bndinfo2.edges.boundaryType;
    lab = (lab(1:end/2)>0) + 2*(lab(end/2+1:end)>0);         

    printOcclusionResultWithContact(im, bndinfo2, lab, outname, contact, 1);
    end
    
    %% results
    resdirs = {ourdir1, geomdir1, ncutdir1};
    outdirs = {ourdir2, geomdir2, ncutdir2};
    
    for k = 1 %:numel(resdirs)

        load([resdirs{k} bn '_seg.mat']);
        %try
            if k==1
                writeDepthImages(resdirs{k}, fn(f), outdirs{k});                
                load([outdirs{k} bn '_contact.mat']);
            end
%         catch
%             lasterr
%             contact = {};
%         end
if 0
        try
            lab = bndinfo.edges.boundaryType;
            lab = lab(1:end/2) + 2*lab(end/2+1:end);
        catch
            lab = [];
        end

        outname = [outdirs{k} bn '_res.jpg'];    
        printOcclusionResultWithContact(im, bndinfo, lab, outname, contact, 1);
end
    end
end