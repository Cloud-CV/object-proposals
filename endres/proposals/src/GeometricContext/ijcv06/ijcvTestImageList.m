function [pg, smaps, imsegs] = ijcvTestImageList(fn, imsegs, classifiers, laboutdir, confoutdir)
% Computes label probabilities for a list of images
% fn should be full path

segcmd = '/IUS/vmr7/dhoiem/segmentation/pedro/segment/segment 0.8 100 100';

if ~exist('imsegs') || isempty(imsegs) || iscell(imsegs)
    createimsegs = 1;
else
    createimsegs = 0;
end

for f = 1:numel(fn)

    try
        im = im2double(imread(fn{f}));
        disp([num2str(f) ': ' fn{f}])

        if createimsegs
            imwrite(im, './tmpim.ppm');
            args{1} = [segcmd ' tmpim.ppm' ' ./tmpsp.ppm'];
            args{2} = './tmpsp.ppm';
            [pg{f}, smaps{f}, imsegs(f)] = ijcvTestImage(im, args, classifiers);
            toks = strtokAll(fn{f}, '/');
            imsegs(f).imname = toks{end};
            delete('./tmpsp.ppm');
            delete('./tmpim.ppm');
        else         
            [pg{f}, smaps{f}] = ijcvTestImage(im, imsegs(f), classifiers);
        end


        if exist('laboutdir') && ~isempty(laboutdir)
            toks = strtokAll(fn{f}, '/');
            imdir = [];
            for k = 1:numel(toks)-1
                imdir = [imdir '/' toks{k}];
            end  
            writeAllLabeledImages(imdir, imsegs(f), pg(f), laboutdir);
        end
        if exist('confoutdir') && ~isempty(confoutdir)    
            [cimages, cnames] = pg2confidenceImages(imsegs(f), pg(f));
            save([confoutdir '/' strtok(imsegs(f).imname, '.') '.c.mat'], 'cimages', 'cnames');        
            writeConfidenceImages(imsegs(f), pg(f), confoutdir);
        end
    catch
        disp(lasterr)
    end
end