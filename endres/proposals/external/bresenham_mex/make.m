% tested on win32 platform + VC7
% it may also work well on other platfoms/compilers
mex -O SegInMat.cpp bresenham.cpp
mex -O LineTwoPnts.cpp bresenham.cpp