function m = similarity(sp1, sp2, opts)
% Returns the similarity score of two superpixels using various methods
% As seen with Matlab profiler, this function is responsible for majority
% of calculation for the whole algorithm.

d = zeros(1, length(opts.features));
a = 1;

for fn = 1:length(opts.features)

    % Intersection distance
    %d(fn) = 1 - sum(min([sp1.hist{fn}, sp2.hist{fn}], [], 2));   
    % Hellinger's distance (Hellinger's kernel)
    %d(fn) = sqrt(sum((sqrt(sp1.hist{fn}) - sqrt(sp2.hist{fn})).^2));    
    % l^1 distance (Intersection kernel)
    %d(fn) = sum(abs(sp1.hist{fn} - sp2.hist{fn}));
    
    if opts.features(fn) == 6 % size
        d(fn) = sp1.size + sp2.size;     
        a = min(sp1.size, sp2.size); % for removing very small superpixels early
    else
        d(fn) = 0.5*sum(((sp1.hist{fn} - sp2.hist{fn}).^2)./(eps + sp1.hist{fn} + sp2.hist{fn})); % \chi^2 distance (\chi^2 kernel)
    end 
    
end

d = 1 - d; % Low distance = high similarity. This is the monotone decreasing mapping we use
m = sum(d.*opts.feature_weights)/sum(opts.feature_weights); % The similarity value. If weights are ones, then this is just mean(d)

% Force small superpixels to merge first
if a < 0.002
    m = 10 + m; % adding constant will preserve the original ordering among overloaded pairs
end


