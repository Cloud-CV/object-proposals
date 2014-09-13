% @authors:     Fuxin Li
% @contact:     fli@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function samples = systematic_sampler(quality, num_samples)
% Sampling without replacement systematically
    [sort_quality,ind] = sort(quality,'descend');
    quality_sum = cumsum(sort_quality);
    stratas = (1:num_samples) * (quality_sum(end) / num_samples);
% Make sure we are not plagued by precision errors
    stratas(end) = quality_sum(end);
    sample_end = 0;
    samples = zeros(num_samples,1);
% Sample the first one from each strata
    for i=1:num_samples
        sample_start = sample_end + 1;
        sample_end = find(quality_sum >= stratas(i),1,'first');
        samples(i) = ind(sample_start);
    end
end