function integralImage = computeIntegralImage(table)

integralImage = cumsum(table,1); integralImage = cumsum(integralImage,2);
[height width] = size(table);
%set the first row and the first column 0 in the integral image
integralImage =[zeros(height,1) integralImage];
integralImage=[zeros(1,width+1); integralImage];
