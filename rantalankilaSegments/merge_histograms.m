function new_hist = merge_histograms(sp, parts)
% Merges the histograms of several superpixels by weighting the individual
% histograms by the superpixel sizes. This gives the actual histogram of
% the combined superpixel.

partsize = zeros(1, length(parts));
for i = 1:length(parts)
    partsize(i) = sp{parts(i)}.size;
end

for fn = 1:length(sp{1}.hist)
    new_hist{fn} = zeros(length(sp{1}.hist{fn}),1);
    cc = 0;
    for i = 1:length(parts)
        cur_hist = sp{parts(i)}.hist{fn};
        if sum(cur_hist) > 0 % skip empty histograms
            new_hist{fn} = new_hist{fn} + partsize(i)*cur_hist;
            cc = cc + partsize(i);
        end
    end
    if cc > 0
        new_hist{fn} = new_hist{fn}/cc; % normalization
    else
        % If there are only empty histograms, the output histogram remains as a vector of zeros
    end
end





