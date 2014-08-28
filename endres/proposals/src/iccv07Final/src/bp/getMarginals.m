function marginal = getMarginals(joint, i)
% Computes marginal along dimension i of the joint likelihood given by
% joint.

nvals = size(joint, i);

%joint = shiftdim(joint, i); % make i the last dimension (for easy indexing)
ndimsj = ndims(joint);
n = rem(i,ndimsj); 
if ~isequal(n,0)
    joint = permute(joint, [n+1:ndimsj 1:n]);
end


numjoint = numel(joint);
numOtherVals = numjoint / nvals; 
subind = (1:numOtherVals); % indiced for variable_i = 1

marginal = zeros(nvals, 1);
joint = reshape(joint, [numjoint 1]);
for k = 1:nvals    
    marginal(k) = sum(joint(subind + (k-1)*numOtherVals));
end