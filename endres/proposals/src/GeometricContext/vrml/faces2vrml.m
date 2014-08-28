function faces2vrml(dir, filename, points3D, tpoints2D, faces, gim, vim, varargin)
% faces2vrml(dir, filename, points3D, tpoints2D, faces, gim, vim, varargin)
% Writes faces to vrml file and saves texture map images.
% 
% dir = the directory where the files are to be written
% filename = the base filename for the vrml file and texture map
% points3D(1:3, nvertices)  = 3 x n cell array of 3D vertices (x, y, z)
% tpoints2D{nfaces}(1:2, npoints) = n x 1 cell array of 2D texture image
%                                   coords (x, y)
% faces{nfaces}(npoints) = sets of indices corresponding to vertices
% img = the texture map image
%
%points3D = points3D(:, 1:8);
%tpoints2D = tpoints2D(1:2);
%faces = faces(1:2);
%
% Copyright(C) Derek Hoiem, Carnegie Mellon University, 2005
% Permission granted to non-commercial enterprises for
% modification/redistribution under GNU GPL.  
% Current Version: 1.0  09/30/2005

% test to see if textured ground plane exists
gexists = ~isempty(faces{1});

gcolor = [0.0 1.0 0.0];
scolor = [0.4 0.6 0.95];
simageset = 0;

if length(varargin) >= 1 % get ground color
    gcolor = varargin{1};
end   
if length(varargin) >= 2 % get sky color
    scolor = varargin{2};
end
if length(varargin) >= 3
    skyimname=  varargin{3};
    simageset = 1;
end

disp(['writing vrml file to ' [dir '/' filename '.wrl']]);

% write ground and vert texture images
if gexists
    gimname = [dir '/' filename '.g.png'];
    imwrite(gim, gimname, 'png', 'Transparency', [0 0 0]);
    gimname = ['"' filename '.g.png"'];
end

vimname = [dir '/' filename '.v.png'];
if size(vim, 3) ~= 4
    imwrite(vim, vimname, 'png', 'Transparency', [0 0 0]);
else
    imwrite(vim(:, :, 1:3), vimname, 'png', 'Alpha', vim(:, :, 4));
end
    
vimname = ['"' filename '.v.png"'];

fid = fopen([dir '/' filename '.wrl'], 'w');

% header
fprintf(fid,'#VRML V2.0 utf8\n\n');

% sky and ground background
if 0 
fprintf(fid,'Background {\n');
fprintf(fid, '  skyColor   [%4.2f, %4.2f, %4.2f]\n', scolor);
if simageset
    fprintf(fid, '  frontUrl   "%s"\n', skyimname);
end
fprintf(fid, '  groundColor  [%4.2f %4.2f, %4.2f %4.2f, %4.2f %4.2f]}\n\n', imresize(gcolor, [6 1]));
end
fprintf(fid, 'NavigationInfo {\n');
fprintf(fid, '  headlight FALSE \n');
fprintf(fid, '  type ["FLY", "ANY"]}\n\n');
  

if 1
%fprintf(fid, '    Separator {\n');
fprintf(fid, 'Viewpoint {\n');
fprintf(fid, '    position        0 5.0 0.0\n');
fprintf(fid, '    orientation     0 0 0 0\n');
fprintf(fid, '    fieldOfView     %6.4f\n', .768);
fprintf(fid, '    description "Original"\n');
fprintf(fid, '}\n\n');
%fprintf(fid, '       }\n   }\n\n');
end

%% FACES and TEXTURES
% for each polygon do:-
nfaces = numel(faces);

if 0
% make ground plane
fprintf(fid, 'Shape {\n  ');    
fprintf(fid, '  appearance Appearance {\n');
fprintf(fid, '      material Material {\n');
fprintf(fid, '			emissiveColor %4.2f %4.2f %4.2f \n', gcolor);	
fprintf(fid, '          ambientIntensity 0.0 } } \n');
fprintf(fid, '  geometry IndexedFaceSet {\n');
fprintf(fid, '    solid FALSE\n'); 
fprintf(fid, '    coord Coordinate{\n');
fprintf(fid, '       point [\n');
fprintf(fid, '          %6.2f  %6.2f  %6.2f,\n', 2000*[-1 -0.001 -1] );
fprintf(fid, '          %6.2f  %6.2f  %6.2f,\n', 2000*[ 1 -0.001 -1] );
fprintf(fid, '          %6.2f  %6.2f  %6.2f,\n', 2000*[ 1 -0.001 1] );
fprintf(fid, '          %6.2f  %6.2f  %6.2f ] }\n', 2000*[-1  -0.001 1] );
fprintf(fid, '    coordIndex [\n'); 
fprintf(fid, '          %d  %d  %d  %d  -1]\n', [0 1 2 3]);
fprintf(fid, '   }}\n\n');
end

nf = 0;
ngf = 0;

[points3D, tmp, U]  = unique(points3D', 'rows');
points3D = points3D';

%%%%%%%%%%%%%%%%%%%
%%% GROUND FACE %%%
%%%%%%%%%%%%%%%%%%%
if gexists
    
	fprintf(fid, 'Shape {\n  appearance Appearance {\n    texture ImageTexture {\n');
	fprintf(fid, '     url %s', gimname);
	fprintf(fid, '\n    }\n  }\n'); 
	fprintf(fid, '  geometry IndexedFaceSet { \n');
	fprintf(fid, '    solid FALSE\n'); 
	
	% VERTICES    
	fprintf(fid, '    coord Coordinate {\n      point [ ');
	nvertices = size(points3D, 2);
	for i = 1:nvertices
        if i>1
            fprintf(fid,','); 
        end
        fprintf(fid,'\n        %6.2f  %6.2f %6.2f', points3D(:, i)'); 
	end
	fprintf(fid,' ]    \n}\n\n');
		
	% FACE INDICES
	fprintf(fid, '    coordIndex [ ');    
	fprintf(fid, '\n        ');
	for nf = 1:nfaces
        if isempty(faces{nf})
            break;
        end
		npoints = numel(faces{nf});
		for i = 1:npoints
            fprintf(fid, ' %d', U(faces{nf}(i))-1);
		end
        if nf < nfaces
        	fprintf(fid, ' -1,\n        ');
        end
	end
    ngf = nf;
	fprintf(fid, '\n        ]\n');
		
	% TEXTURE COORD
	fprintf(fid, '    texCoord  TextureCoordinate {\n      point [');
	for n = 1:nfaces
        if isempty(faces{n})
            break;
        end
        npoints = numel(faces{n});
		for i = 1:npoints
            if i>1 | n > 1
                fprintf(fid,','); 
            end; %if
            texture_coord = tpoints2D{n}(1:2,i)';
            fprintf(fid,'\n        %6.4f  %6.4f', texture_coord); 
		end; %for	
	end
	fprintf(fid,'\n        ] \n    }\n');
		
	% TEXTURE IND
	fprintf(fid,'    texCoordIndex [ ');
	count = 0;
	for n = 1:nfaces 
        if isempty(faces{n})
            break;
        end
        npoints = numel(faces{n});
        fprintf(fid, '\n        ');
		for i = 1:npoints
            count = count + 1;
            fprintf(fid, '%d ', count-1);
		end
        if n < nfaces
        	fprintf(fid, '-1,');
        end
	end;
	fprintf(fid,'\n        ]}\n}\n\n');
    
end
% ngf is number of faces used by ground
if 1
%%%%%%%%%%%%%%%%%%%%%%
%%% VERTICAL FACES %%%
%%%%%%%%%%%%%%%%%%%%%%
fprintf(fid, 'Shape {\n  appearance Appearance {\n    texture ImageTexture {\n');
fprintf(fid, '     url %s', vimname);
fprintf(fid, '\n    }\n  }\n'); 
fprintf(fid, '  geometry IndexedFaceSet { \n');
fprintf(fid, '    solid FALSE\n'); 
fprintf(fid, '    creaseAngle 0.0\n');

% VERTICES
fprintf(fid, '    coord Coordinate {\n      point [ ');
nvertices = size(points3D, 2);
for i = 1:nvertices
    if i>1
        fprintf(fid,','); 
    end
    fprintf(fid,'\n        %6.2f  %6.2f %6.2f', points3D(:, i)'); 
end
fprintf(fid,' ]    \n}\n\n');

% FACE INDICES
fprintf(fid, '    coordIndex [ ');    
fprintf(fid, '\n        ');
for n = ngf+1:nfaces
	npoints = numel(faces{n});
	for i = 1:npoints
        fprintf(fid, ' %d', U(faces{n}(i))-1);
	end
    if n < nfaces
    	fprintf(fid, ' -1,\n        ');
    end
end
fprintf(fid, '\n        ]\n');

% TEXTURE COORD
fprintf(fid, '    texCoord  TextureCoordinate {\n      point [');
for n = ngf+1:nfaces
    npoints = numel(faces{n});
	for i = 1:npoints
        if i>1 | n > 1
            fprintf(fid,','); 
        end; %if
        texture_coord = tpoints2D{n}(1:2,i)';
        fprintf(fid,'\n        %6.4f  %6.4f', texture_coord); 
	end; %for	
end
fprintf(fid,'\n        ] \n    }\n');

% TEXTURE IND
fprintf(fid,'    texCoordIndex [ ');
count = 0;
for n = ngf+1:nfaces 
    npoints = numel(faces{n});
    fprintf(fid, '\n        ');
	for i = 1:npoints
        count = count + 1;
        fprintf(fid, '%d ', count-1);
	end
    if n < nfaces
    	fprintf(fid, '-1,');
    end
end;
fprintf(fid,'\n        ]}\n}\n\n');
end

fclose(fid);
