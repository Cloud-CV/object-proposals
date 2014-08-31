function Q = computeQuantMatrix(imgLAB,bins)
%compute the quantization matrix based on the 3-dimensional matrix imgLAB

if length(bins) ~= 3
    error('Need 3 bins for quantization');
end

L = imgLAB(:,:,1);
a = imgLAB(:,:,2);
b = imgLAB(:,:,3);

ll = min(floor(L/(100/bins(1))) + 1,bins(1));
aa = min(floor((a+120)/(240/bins(2))) + 1,bins(2));
bb = min(floor((b+120)/(240/bins(3))) + 1,bins(3));

Q = (ll-1)* bins(2)*bins(3) + (aa - 1)*bins(3) + bb;