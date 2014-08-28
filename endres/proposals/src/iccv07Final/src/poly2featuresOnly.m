function feat = poly2featuresOnly(u, v, imsize, v0, yc, f)

imh = imsize(1);
imw = imsize(2);

if isempty(f)
    f = 1.38; %S*max(size(im)) / imh;
end

u = u(:)'; 
v = v(:)';

[tmp, ind] = min(u);
u = [u(ind:end)  u(1:ind-1)];
v = [v(ind:end)  v(1:ind-1)];

u = (u - imw/2) ./ imh;
v = 1 - (v ./ imh);

[v1, ind1] = min(v); % lowest point on object in image

[footx, footz] = computeGroundPosition([min(u) max(u)], [v1 v1], v0, yc, f);
footz(2) = footz(1) + footx(2)-footx(1);

[cx, cz] = computeGroundPosition(u, v, v0, yc, f);

data.u = (u*imh+imw/2)';
data.v = ((1-v)*imh)';
data.x3d = cx;
data.z3d = cz;
data.foot = [footx footz];

feat = contactdata2features(data);










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, z] = computeGroundPosition(u, v, v0, yc, f)

z = yc*f./max((v0-v), 0.001);
x = u.*z./f;
    