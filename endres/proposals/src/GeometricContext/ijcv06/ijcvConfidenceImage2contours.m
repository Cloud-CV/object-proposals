function [x, y] = ijcvConfidenceImage2contours(confim, maxy)

[imh, imw] = size(confim);

confim = imfilter(confim, fspecial('gaussian', 25, 7), 'same');

if ~exist('maxy')
    maxy = imh-15;
end

x = [15:imw-15];

cval = [0.25 0.5 0.75];

for c = 1:numel(cval)

    for i = 1:numel(x)
        try
            y{c}(i) = max(find(confim(1:maxy, x(i))>cval(c)));
        catch
            y{c}(i) = 1;
        end
    end
    
end

        
    

