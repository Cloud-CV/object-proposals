imgExample = imread('002053.jpg');
boxes = runObjectness(imgExample,10);
figure,imshow(imgExample),drawBoxes(boxes);