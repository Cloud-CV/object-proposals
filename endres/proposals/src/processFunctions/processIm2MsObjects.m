function [object_maps] = processIm2MsObjects(im, varargin)

%% Set parameters
classifiers = varargin{1};


if max(size(im))>640
   fprintf('Warning, image is awfully large, consider resizing\n');
%  im = imresize(im, 640/max(size(im)), 'bilinear');
end


%% Classify surfaces

%prefix = num2str(floor(rand(1)*10000000));
%fn1 = ['./tmpim' prefix '.ppm'];
%fn2 = ['./tmpimsp' prefix '.ppm'];

%segcmd = '~/prog/tools/segment/segment 0.8 100 100';
%args{1} = [segcmd ' ' fn1 ' ' fn2];
%args{2} = fn2;
args = {0.8 100 100};
% number of segments per segmentation
nsegments = [5 7 10 15 20 25 35 50 60 70 80 90 100 Inf]; 
% do not make pixel confidences sum to 1
normalize = 0;

%imwrite(im, fn1);
[pg, tmp, imsegs] = msTestImage2(im, args, classifiers, nsegments, normalize);


object_maps = msPg2confidenceImages(imsegs, {pg});
object_maps = object_maps{1};
