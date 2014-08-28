function [points3D, tpoints2D, faces, flabels] = ...
    APPplanes2faces(gplanes, vplanes, imsize, varargin)
% [points3D, tpoints2D, faces, flabels] = ...
%    APPplanes2faces(gplanes, vplanes, imsize, varargin)
% 
% points3D(1:3, nvertices)  = 3 x n cell array of 3D vertices (x, y, z)
% tpoints2D{nfaces}(1:2, npoints) = n x 1 cell array of 2D texture image coords (x, y)                                  
% faces{nfaces}(npoints) = sets of indices corresponding to vertices
%
% First, the X (left-right) and Y (how far from viewer) 
% positions are determined as if the scene is entirely
% ground and sky.  The intersection of each non-ground plane with the ground
% is given by b=planes(n).gndln_b and planes(n).gndln_m (y = mx + b).  Once
% the ground intersection is determined, the height is determined based on
% the y-value of each block in the image.
%
% Copyright(C) Derek Hoiem, Carnegie Mellon University, 2005
% Permission granted to non-commercial enterprises for
% modification/redistribution under GNU GPL.  
% Current Version: 1.0  09/30/2005

nfaces = ~isempty(gplanes);
for i = 1:length(vplanes)
    nfaces = nfaces + length(vplanes(i).sinfo);
end

nvplanes = length(vplanes);

height = imsize(1);
width = imsize(2);
%disp(num2str([height width]))


points3D = zeros(3, nfaces*20);
faces = cell(nfaces, 1);
tpoints = cell(nfaces, 1);
flabels = cell(nfaces, 1);

if length(varargin) == 1
    iny = varargin{1};
else
    iny = 0.5;
end
miny = height;
if ~isempty(gplanes)
    for i = 1:length(gplanes(1).sinfo)
        miny = min([min(gplanes.sinfo{i}.y) miny]);
    end    
end
maxy = 0;
if 0
for p = 1:length(planes)
    if strcmp(planes(p).label, 'sky')
        for s = 1:length(planes(p).sinfo)
            maxy = max(max(planes(p).sinfo{s}.y), maxy);
        end
    end
end
end
grassy = 1- (miny / height);
skyy = 1- (maxy / height);

if skyy < grassy % means that sky occurred below ground (shouldn't happen)    
    horizy = grassy + 2/height;
else
    if iny > grassy & iny < skyy  % input horizon within possible bounds
        horizy = iny;
    else
        horizy = grassy + 2/height; 
    end
end
horizy = max(horizy, (height-miny+10)/height);

%disp('fixing horizon at 0.5')
%horizy = 0.5;

%disp(horizy)

fovy = 40*pi/180;
fovx = width/height*fovy;

thetay0 = pi/2 - fovy*horizy;
thetax0 = -fovx/2;
h0 = 5.0;

gX = zeros(height+1, width+1);
gY = zeros(height+1, width+1);

z0 = 0.0;

fi = 0;
npts = 0;
np = 0;

% create ground plane
if ~isempty(gplanes)
      
    sinfo = gplanes(1).sinfo;    

    for s = 1:length(sinfo)
        for i = 1:length(sinfo{s}.x)
            w = sinfo{s}.x(i);
            h = sinfo{s}.y(i);                               
            thetay = thetay0 + (1-(h-1)/(height-1))*fovy;   
            npts = npts + 1;
            gy = (h0 - 0)*tan(thetay);
            xw = gy*tan(fovx/2)*2;
            gx = -xw/2 + (w-1)/(width-1)*xw; 
            points3D(1:3, npts) = [gx gy 0.0]';
        end
        
        fp = npts-length(sinfo{s}.x);
        np = np + 1;
        faces{np} = [fp+1:npts];    
        flabels{np} = '000';
        for i = 1:length(sinfo{s}.x)
            x = (sinfo{s}.x(i)-1)/(width-1);
            y = 1-(sinfo{s}.y(i)-1)/(height-1);
            tpoints2D{np}(1:2, i) = [x y]';
        end                
    end
end
np = np + 1;
faces{np} = []; % mark end of ground as empty bracket

% create vertical planes
for p = 1:length(vplanes)
    
    label = vplanes(p).label(1:3);     
    sinfo = vplanes(p).sinfo;
        
    for s = 1:length(sinfo)
       
        np = np + 1;        
        for i = 1:length(sinfo{s}.x)

            npts = npts + 1;            
            
            w = sinfo{s}.x(i);
            h = sinfo{s}.y(i);                    
            thetay = thetay0 + (1-(h-1)/(height-1))*fovy;              

            x = (w-1)/(width-1);
            y = min(max(piecewise_linear_spline_val(x, vplanes(p).gfit), 1-horizy+0.001), 1); 

            gthetay = thetay0 + (1-y)*fovy;  
            gy = h0*tan(gthetay);
            xw = gy*tan(fovx/2)*2;
            gx = -xw/2 + x*xw;

            z = h0-(gy/tan(thetay));
            points3D(1:3, npts) = [gx  gy  z]';

        end %points in segment
            
        fp = npts-length(sinfo{s}.x);
        faces{np} = [fp+1:npts];     
        flabels{np} = label;
        for i = 1:length(sinfo{s}.x)
            x = (sinfo{s}.x(i)-1)/(width-1);
            y = 1-(sinfo{s}.y(i)-1)/(height-1);
            tpoints2D{np}(1:2, i) = [x y]';
        end                

    end  % segments in plane
    
end % planes

points3D = points3D(:, 1:npts);

tmppoints = points3D;
points3D(2, :) = tmppoints(3, :);
points3D(3, :) = -tmppoints(2, :);


