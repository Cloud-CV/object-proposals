function im = wheel2square(hrange, srange, wrad)

im = zeros(2*wrad, 2*wrad);

for ty = 1:2*wrad
    for tx = 1:2*wrad
        y = ty-1/2 - wrad;
        x = tx-1/2 - wrad;
        r = sqrt(y^2 + x^2);
        if r <= wrad
            theta = atan2(x, y);
            theta = theta + (theta<0)*2*pi;
            [tmp, sind] = min(abs(srange-r/wrad));
            [tmp, hind] = min(abs(hrange-theta/2/pi));
            im(ty, tx) = (hind-1)*numel(hrange) + sind;
        end
    end
end



