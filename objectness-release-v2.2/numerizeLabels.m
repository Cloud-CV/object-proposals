function N = numerizeLabels(S)

% converts the segmentation image S from true-color
% to ordered integer labels
%

N = zeros(size(S,1),size(S,2),'uint16');
col2n = zeros(256,256,256);
totcol = 0;
for x = 1:size(S,2)
    for y = 1:size(S,1)
        p = reshape(S(y,x,:),1,3)+1;
        cix = col2n(p(1),p(2),p(3));
        if cix > 0
          N(y,x) = cix;
        else
          totcol = totcol+1;
          col2n(p(1),p(2),p(3)) = totcol;
          N(y,x) = totcol;
        end
    end
end
