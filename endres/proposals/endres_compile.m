function  endres_compile
%ENDRES_COMPILE Summary of this function goes here
%   Detailed explanation goes here
root_dir = pwd;
display('compiling endres ...');
mex external/segment/segment_fh_mex.cc;
cd external/maxflow-v3.01
%mex external/maxflow-v3.01/mex_maxflow.cpp;
compile;
cd(root_dir);
cd external/bresenham_mex
make;
cd(root_dir);
%mex external/bresenham_mex/SeginMat.cpp;
%mex external/bresenham_mex/LineTwoPnts.cpp;
mex src/GeometricContext/tools/misc/treevalc.cc;
mex external/pwmetric/pwmetrics_cimp.cpp;
mex external/pwmetric/pwhamming_cimp.cpp;
mex src/objectProposals/utils/get_region_overlap_mex.cc;
display('endres compilation complete');
end

