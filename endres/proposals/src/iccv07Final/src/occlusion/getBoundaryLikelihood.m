function p = getBoundaryLikelihood(x, w)
% p = getBoundaryLikelihood(x, w)

DO_PER_ITER = size(w, 2)>1;
if size(x, 2)>size(w, 1)-1
    x = x(:, 1:size(w,1)-1);
end

if ~DO_PER_ITER
    p = lrLikelihood(full(x), w);  
else  % see trainBoundaryClassifier
    p = zeros(size(x, 1), 1);
    for k = 1:4
        if k < 4
            ind = x(:, k)>0 & x(:, k+1)==0;
        else
            ind = x(:, k)>0;
        end
        p(ind) = lrLikelihood(full(x(ind, :)), w(:, k));
    end
end