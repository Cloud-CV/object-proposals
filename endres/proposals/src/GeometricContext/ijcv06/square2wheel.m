function im = square2wheel(valim)

im = size(valim);

[imh, imw] = size(valim);


for ty = 1:imh
    for tx = 1:imw
        r = 1-ty/imh;
        theta = tx/imw*2*pi;
        theta = theta - (theta>pi)*(2*pi);
        x = ceil(r*cos(theta)*imw/2+imw/2);
        y = ceil(r*sin(theta)*imh/2+imh/2);
        
        im(ty, tx) = (x-1)*imh + y;
    end
end



