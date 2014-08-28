function val = weight(rank, w)

if(~exist('w','var'))
   w = 30000;
end

val= exp(-(rank-1).^2./w);

