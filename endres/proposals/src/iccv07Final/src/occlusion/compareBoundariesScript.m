% compareBoundariesScript

savedir = '~/data/occlusion/labelme/figs/bnd_im';

folder = db(f).annotation.folder; 
imfn = db(f).annotation.filename;
bn = strtok(imfn, '.');



im = imread(fullfile(imdir, folder, imfn));
figure(1), hold off, imagesc(im); axis image

load(fullfile(basedir, 'pb2', folder, [bn '_pb2_ucm']), 'ucm');
im = im2double(imresize(im, size(ucm), 'bilinear'));
imwrite(im, fullfile(savedir, imfn), 'Quality', 95);
grayim = rgb2gray(im2double(im));
h = 0*ones(size(grayim)); 
ucm = im2double(ucm);
pb = ucm / max(ucm(:));
tmpim = ordfilt2(max(pb, 0), 9, ones(3));
dispim = tmpim;%dispim = hsv2rgb(h, tmpim, 0.5*grayim+0.5*tmpim);
figure(2), hold off,  imagesc(dispim), axis image, colormap gray
imwrite(dispim, fullfile(savedir, [bn '_pb2_ucm.jpg']), 'Quality', 95);

load(fullfile(basedir, 'pb', folder, [bn '_pb']), 'pb');
grayim = rgb2gray(im2double(im));
h = 0*ones(size(grayim)); 
pb = pb / max(pb(:));
tmpim = ordfilt2(max(pb, 0), 9, ones(3));
dispim = tmpim;%dispim = hsv2rgb(h, tmpim, 0.5*grayim+0.5*tmpim);
figure(5), hold off,  imagesc(dispim), axis image
imwrite(dispim, fullfile(savedir, [bn '_pb.jpg']), 'Quality', 95);

load(fullfile(basedir, 'pb2', folder, [bn '_pb2']), 'pb');
grayim = rgb2gray(im2double(im));
h = 0*ones(size(grayim)); 
pb = pb / max(pb(:));
tmpim = ordfilt2(max(pb, 0), 9, ones(3));
dispim = tmpim;%dispim = hsv2rgb(h, tmpim, 0.5*grayim+0.5*tmpim);
figure(5), hold off,  imagesc(dispim), axis image
imwrite(dispim, fullfile(savedir, [bn '_pb2.jpg']), 'Quality', 95);

load(fullfile(occdir, folder, [bn '_occlusion']), 'bndinfo_all');
occ.po_all = getOcclusionMaps(bndinfo_all); 
occim = mean(occ.po_all, 3);
%occim = im2double(imread(fullfile(basedir, 'results', folder, [strtok(imfn, '.') '_occ.jpg'])));
occim = occim/max(occim(:));
%h=0.65*ones(size(grayim));
tmpim = ordfilt2(occim, 9, ones(3));
dispim = tmpim;%dispim = hsv2rgb(h, tmpim, 0.5*grayim+0.5*tmpim);
figure(3), hold off, imagesc(dispim); axis image
imwrite(dispim, fullfile(savedir, [bn '_occave.jpg']), 'Quality', 95);

occim = occ.po_all(:, :, 1);
occim = occim/max(occim(:));
tmpim = ordfilt2(occim, 9, ones(3));
dispim = tmpim;%dispim = hsv2rgb(h, tmpim, 0.5*grayim+0.5*tmpim);
figure(6), hold off, imagesc(dispim); axis image
imwrite(dispim, fullfile(savedir, [bn '_occ1.jpg']), 'Quality', 95);

load(fullfile(basedir, 'labels2', folder, [bn '_labels']));
bmap = seg2bmap(lim, size(pb, 2), size(pb, 1));
bmap(:, [1:10 end-9:end]) = 0;
bmap([1:10 end-9:end], :) = 0;
tmpim = ordfilt2(double(bwmorph(bmap,'thin',inf)), 25, ones(5));
tmpim = cat(3, tmpim>0, zeros([size(tmpim) 2]));
dispim = im2double(im);
dispim(repmat(tmpim(:, :, 1)>0, [1 1 3])) = tmpim(repmat(tmpim(:, :, 1)>0, [1 1 3]));
%dispim = min(max(hsv2rgb(h, tmpim, 0.5*grayim+0.5*tmpim), 0), 1);
figure(4), hold off, imagesc(dispim); axis image,
imwrite(dispim, fullfile(savedir, [bn '_gt.jpg']), 'Quality', 95);

fid = fopen(fullfile(savedir, [bn '_ap.txt']), 'w');
fprintf(fid, 'index = %f   pb = %f   pb2+ucm = %f   occ1 = %f   occave = %f \n', sind(f), pr_pb(f).ap, pr_ucm(f).ap, pr_occ1(f).ap, pr_occave(f).ap);
fclose(fid);

disp([imfn ':  ' num2str([pr_pb2(f).ap pr_occave(f).ap])])

% grayim = imresize(rgb2gray(im2double(im)), size(pb), 'bilinear');
% resultim = repmat(grayim, [1 1 3]);
% tmpim = ordfilt2(max(pb,0), 9, ones(3));
% resultim((tmpim>0.05)) = tmpim(tmpim>0.05);
% tmpim = ordfilt2(occim, 9, ones(3));
% resultim(find(tmpim>0.05)+numel(tmpim)) = tmpim(tmpim>0.05);
% figure(4), hold off, imagesc(resultim), axis image