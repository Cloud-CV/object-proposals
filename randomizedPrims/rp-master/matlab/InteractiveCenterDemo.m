function InteractiveCenterDemo(configFile)

  global h pcs proposals I selections files imgId imgDir
  clc;

  %% Load image:
  imgFile = [imgDir '/' files(imgId).name];
  I = imread(imgFile);

  configParams = LoadConfigFile(configFile);

  %% Compute proposals:
  ticId = tic;
  proposals = RP(I, configParams); %[xmin, ymin, xmax, ymax]
  fprintf('RP generated proposals in %0.2f seconds!\n', toc(ticId));
  disp('---------------------------------------------');

  %% Compute proposals center
  pcs = ComputeCenters(proposals); %[xc yc]

  %% Display
  h = figure(1);
  clf;
  imshow(I, 'Border', 'tight');
  hold on;
  disp('Move the cursor close to the center of an object to see if it has been found. The closest proposal is shown in yellow.');
  disp('Left click to select an object and right click to go to next image...');
  selections = [];

end

function centers = ComputeCenters(boxes)
  centers = [(boxes(:, 3) + boxes(:, 1)) ./ 2, (boxes(:, 4) + boxes(:, 2)) ./ 2]; %[xc yc]
end










