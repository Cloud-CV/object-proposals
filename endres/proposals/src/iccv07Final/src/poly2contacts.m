function [cu, cv, cx, cz, footprint, feat] = poly2contacts(dt, u, v, imsize, v0, yc, f, minp, im)

if ~exist('minp', 'var')
    minp = 0.5;
end

imh = imsize(1);
imw = imsize(2);

if isempty(f)
    f = 1.38; %S*max(size(im)) / imh;
end

u = u(:)'; 
v = v(:)';
if exist('im', 'var')
    figure(1), hold off, imshow(im), hold on    
    plot([u(:) ; u(1)]', [v(:) ; v(1)]', '-b');
end

[tmp, ind] = min(u);
u = [u(ind:end)  u(1:ind-1)];
v = [v(ind:end)  v(1:ind-1)];

u = (u - imw/2) ./ imh;
v = 1 - (v ./ imh);

if exist('im', 'var')
    figure(1), plot(u*imh+imw/2, (1-v)*imh, '-g')
end
cind = convhull(u*imh+imw/2, (1-v)*imh);
if exist('im', 'var')
    figure(1), plot(u(cind)*imh+imw/2, (1-v(cind))*imh, '-y')
end

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

[b, nodes] = treeval(dt, feat);

b = b - 1;

ind = dt.classprob(nodes, 2)>minp;%(b==1);

cu = u(ind)*imh+imw/2;
cv = (1-v(ind))*imh;
cz = cz(ind);
cx = cx(ind);
footprint = data.foot;

if exist('im', 'var')
    figure(1), plot(cu, cv, '*r')
    figure(1), plot([1 1000], (1-v0)*imh*ones(1,2), '-b');
end
%keyboard
% get how many points are in the footprint
%figure(2), plot(cx, cz, '*'), axis equal


%disp(num2str([cx ; cz]))








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, z] = computeGroundPosition(u, v, v0, yc, f)

z = yc*f./max((v0-v), 0.001);
x = u.*z./f;
    