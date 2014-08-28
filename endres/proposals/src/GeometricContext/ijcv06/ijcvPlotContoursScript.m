%ijcvPlotContoursScript

outdir = '/IUS/vmr20/dhoiem/data/ijcv06';

imdir = [outdir '/images'];
files = dir([imdir '/*.jpg']);

fn = {files(:).name};

for f = 1:numel(fn)
    im = im2double(imread([imdir '/' fn{f}]));
    cim = im2double(imread([imdir '/confims/' strtok(fn{f}, '.') '_c_090.jpg']));
    cim = cim + im2double(imread([imdir '/confims/' strtok(fn{f}, '.') '_c_sky.jpg']));
    %maxy = round(size(cim, 1)*0.8);
    [x, y] = ijcvConfidenceImage2contours(cim);
    
    figure(1), hold off, imshow(0.5 + 0.5*rgb2gray(im));
    figure(1), hold on, plot(x, y{1}, 'g', 'LineWidth', 4);
    figure(1), hold on, plot(x, y{2}, 'b', 'LineWidth', 4);    
    figure(1), hold on, plot(x, y{3}, 'r', 'LineWidth', 4);  
    print('-f1', '-djpeg90', [imdir '/confims/' strtok(fn{f}, '.') '_nav.jpg']); 
end
