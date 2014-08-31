function score = computeIntegralImageScores(integralImage,windows)

windows = round(windows);
windows(windows == 0) = 1;
%windows = [xmin ymin xmax ymax]
%computes the score of the windows wrt the integralImage
height = size(integralImage,1);
index1 = height*windows(:,3) + (windows(:,4) + 1);
index2 = height*(windows(:,1) - 1) + windows(:,2);
index3 = height*(windows(:,1) - 1) + (windows(:,4) + 1);
index4 = height*windows(:,3) + windows(:,2);
score = integralImage(index1) + integralImage(index2) - integralImage(index3) - integralImage(index4);