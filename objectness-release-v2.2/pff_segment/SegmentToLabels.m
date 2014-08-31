function [ labels ] = SegmentToLabels( segment )
%SEGMENTTOLABELS Convert output so labels start from 1 and are consecutive

values = unique(segment);
labels = zeros(size(segment));
for i = 1:length(values)
    labels(segment==values(i)) = i;
end