function [index]=mvg_scoreSamplingWrapper(score,numberSamples)
% function [index]=mvg_scoreSamplingWrapper(score,numberSamples) is a 
% wrapper to scoreSamplingMex mex algorithm by 
% Bogdan Alexe, Thomas Deselaers, Vittorio Ferrari form Calvin group in ETH Zurich
% The mex file and extra information can be found from 
% http://www.vision.ee.ethz.ch/~calvin/objectness/
 
index=scoreSamplingMex(score,numberSamples,1);

