function WindowButtonDownFcnCallback(a, b)

global h configFile selections current files imgId;

buttonPressed = get(h, 'SelectionType');

if(strcmp(buttonPressed, 'normal'))
  %Left click
  selections = [selections; current];
elseif(strcmp(buttonPressed, 'alt'))
  %Right click
  imgId = imgId + 1;
  if(imgId > numel(files))
    imgId = 1;
  end
  InteractiveCenterDemo(configFile);
end

end