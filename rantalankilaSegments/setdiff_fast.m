function C = setdiff_fast(A,B)
% Set difference of two sets of positive integers (much faster than built-in setdiff)
% C = setdiff_fast(A,B)
% C = A \ B = { things in A that are not in B }
%
% Source: http://www.mathworks.com/matlabcentral/fileexchange/23172-setdiff
% by "Nick"

if isempty(A)
    C = [];
    return;
elseif isempty(B)
    C = A;
    return; 
else % both non-empty
    bits = zeros(1, max(max(A), max(B)));
    bits(A) = 1;
    bits(B) = 0;
    C = A(logical(bits(A)));
end