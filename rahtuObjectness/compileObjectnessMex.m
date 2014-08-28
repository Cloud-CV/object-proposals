function []=compileObjectnessMex(rahtuPath)

%% Compile all mex files needed in the objectness code
fprintf('Compiling mex files...\n');

mex [ rahtuPath '/bescores.c']
mex [ rahtuPath '/integralimage.c']
mex [ rahtuPath '/selectwindows.c']
mex [ rahtuPath '/wsscores.c']
mex [ rahtuPath '/scoreSamplingMex.c']


fprintf('Done!\n');


