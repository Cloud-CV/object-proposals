function joint = getJoint(marginal)
% Computes the d1xd2x...xdn joint probability for the n marginals.
% marginal{i} has di elements.

nvar = length(marginal);
if nvar==1
    joint = marginal{1}(:);
    return;
end
    
jsize = zeros(1, nvar);
for k = 1:nvar
    jsize(k) = length(marginal{k});
end

joint = ones(jsize);

shapesize = ones(1, nvar);
for k = 1:nvar          
    
    shapesize(k) = jsize(k);        
    fullMarginal = reshape(marginal{k}, shapesize); % shiftdim(marginal{k}, -(k-1));
    shapesize(k) = 1;
    
    repsize = jsize;
    repsize(k) = 1;      
    
    fullMarginal = repmat(fullMarginal, repsize); % make marginal size of joint
    joint = joint .* fullMarginal;
end

