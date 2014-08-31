function index = scoreSampling(score,numberSamples,optionReplacement)

% draw numberSamples from score proportional with the scores ;
% sampling with replacement (optionReplacement=1) or without replacement (optionReplacement=0);
% put the resulting indices in index (1 to length(score));

if nargin < 3
    optionReplacement = 1;
end    

index = scoreSamplingMex(score,numberSamples,optionReplacement);

end