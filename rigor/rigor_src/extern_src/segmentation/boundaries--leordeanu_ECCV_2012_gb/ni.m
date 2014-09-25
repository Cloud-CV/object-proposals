function I = ni(I)

   
I = double(I);

I = I - min(I(:));

I = I./(max(I(:))+eps);



end