function im = drawHOG2(hog, hogSize)
% im = drawHOG2(hog, hogSize)
% HOG is directed, draws with arrows

bs = 50;

norient = size(hog, 1)/sum(prod(hogSize, 2));
fprintf('Number orientations: %d\n', norient);
% construct a "glyph" for each orientaion
bim1 = zeros(bs, bs);
bim1(round(bs/2):end,round(bs/2):round(bs/2)+1) = 1; 
bim1(end-(1:2),round(bs/2)-1:round(bs/2)+2) = 1;
bim1(end-(3:4), [round(bs/2)-2 round(bs/2)+3]) = 1;
bim = zeros([size(bim1) norient]); 
bim(:,:,1) = bim1;
for i = 2:norient,
  bim(:,:,i) = imrotate(bim1, (i-1)*360/norient+180, 'crop');
end

% make pictures of positive weights bs adding up weighted glyphs
c = 0;
for t = 1:size(hogSize, 1)
    s = hogSize(t, :);    
    hog(hog < 0) = 0;    
    im{t} = zeros(bs*s(1), bs*s(2));    
    for j = 1:s(2),
        jjs = (j-1)*bs+1:j*bs;
        for i = 1:s(1),
            iis = (i-1)*bs+1:i*bs;          
            for k = 1:norient,
                c = c+1;
                im{t}(iis,jjs) = max(im{t}(iis,jjs), bim(:,:,k) * hog(c));
            end
        end    
    end  
end
