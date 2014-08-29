function []=compileObjectnessMex(rahtuPath)

%% Compile all mex files needed in the objectness code
fprintf('Compiling mex files...\n');

eval(sprintf('mex %s -outdir %s',[ rahtuPath '/bescores.c'], rahtuPath)); 
eval(sprintf('mex %s -outdir %s', [ rahtuPath '/integralimage.c'], rahtuPath));
eval(sprintf('mex %s -outdir %s', [ rahtuPath '/selectwindows.c'], rahtuPath ));
eval(sprintf('mex %s -outdir %s', [ rahtuPath '/wsscores.c'], rahtuPath ));
eval(sprintf('mex %s -outdir %s', [ rahtuPath '/scoreSamplingMex.c'], rahtuPath));

fprintf('Done!\n');


