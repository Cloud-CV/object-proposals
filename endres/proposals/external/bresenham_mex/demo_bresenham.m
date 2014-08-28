%% Compile
% First, run make.m to create mex files.
% NOTE: 
% 1) refer to your Matlab on line help on how to configure mex and
% create mex file
% 2) LineTwoPnts.mexw32 and SegInMat.mexw32(matlabr2006a + win32) are
% already contained in the zip file. check them.
make

%% Line Two Points
% now everything is ready, let's line two arbitrary points in Cartesian
% coordinates
[rr, cc] = LineTwoPnts(-2,-3, 2,4);
disp('The line between (-2,-3) and (2,4): ');
disp('row: ');disp(rr);
disp('col: ');disp(cc);

%% Line Two Points In Matrix
% you may also want to return all the value of a segment within a matrix:
mat = reshape(1:18, 3, 6);
elems = SegInMat(mat, 1,1, 3,5);
disp('mat:'); disp(mat);
disp('the values of line (1,1) and (3,5) within mat: ');
disp(elems);

%% That's it
% have fun:)
