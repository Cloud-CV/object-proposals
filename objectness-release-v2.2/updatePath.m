function params = updatePath(dirRoot,params)

if nargin < 1
    dirRoot = pwd;
end

if nargin < 2
    params = defaultParams(dirRoot);
end


params.trainingImages = [dirRoot '/Training/Images/'];
params.trainingExamples = [dirRoot '/Training/Images/Examples/'];
params.data = [dirRoot '/Data/'];
params.yourData = [dirRoot '/Data/yourData/'];
params.tempdir = [dirRoot '/tmpdir/'];
params.SS.soft_dir =[dirRoot '/segment/'];