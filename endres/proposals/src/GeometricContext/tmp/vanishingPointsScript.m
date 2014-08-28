if 1
[imh, imw, imb] = size(im);

[gy, gx] = gradient(im);
gy = sqrt(sum(gy.^2, 3));
gx = sqrt(sum(gx.^2, 3));
g = sqrt(gx.^2 + gy.^2);
g = g ./ mean(g(:));

ind = g > 1;
theta(ind) = atand(gy(ind) ./ gx(ind));

thetad = ceil(theta * 2);
histt = zeros(1, 21)
for t = 80*2 : 90*2
    tmpt = thetad(ind);
    histt(t-80*2+1) = sum(tmpt(:)==t);
end

ind = ind  & (theta < 45);


for x = 1:imw    
    for y = find(ind(:, x))'
        yind = (max(1, y-1):min(y+1, imh));        
        tmpg = g(yind, x);
        if any(tmpg>g(y, x))
            ind(y, x) = 0;
        end
    end
end

end





bx = imw/50;  by = imh/50;
for y = 1:by:imh
    yind = (y:min(y+by, imh));
    for x = 1:bx:imw
        xind = (x:min(x+bx, imw));
        tmpind = ind(yind, xind);
        if any(tmpind(:))
            tmptheta = theta(yind, xind);
            val = median(tmptheta(tmpind));
            ind2 = (abs(tmptheta - val) < 10) & tmpind;
            if sum(ind2(:)) > sum(tmpind(:))*0.66
                tmpind = tmpind & ind2;
                ind(yind, xind) = tmpind;
            else
                ind(yind, xind) = 0;
            end
        end
    end
end
            
