% Compile All  object proposals

% add current directory as the parent directory
parDir = pwd;

% add jsonlib to path
addpath([parDir '/jsonlab_1.0beta/jsonlab']);
fprintf('Added json encoder/decoder to the path');

% compilation of edge boxes
mex edgeBoxes/releaseV3/private/edgesDetectMex.cpp
mex edgeBoxes/releaseV3/private/edgesNmsMex.cpp
mex edgeBoxes/releaseV3/private/spDetectMex.cpp
mex edgeBoxes/releaseV3/private/edgeBoxesMex.cpp

addpath(genpath([parDir '/edgeBoxes']));

fprintf('Compilation of Edge Boxes finished\n ');



%Validation Code