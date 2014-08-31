function integralHist = integralHistSuperpixels(N)
%comment to be written

N = int16(N);
total_segms = max(max(N));
[height width] = size(N);

integralHist = zeros(height+1,width+1,total_segms);

for sid = 1:total_segms
       
    superpixelMap = not(N - sid);    
    integralHist(:,:,sid) = computeIntegralImage(superpixelMap);
end


end