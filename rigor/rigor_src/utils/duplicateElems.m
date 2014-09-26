function [duplicated_elems] = duplicateElems(elems, num_duplicates)
%DUPLICATEELEMS takes an elems vector of length N and num_duplicates vector
% of length N, and produces a duplicated_elems vector of length
% sum(num_duplicates). Each element in num_duplicates specifies how many
% times an element in elems needs to be replicated.
%
% E.g. on how to do it in a loopy way:
%
%   elems = [2,4,6,7,10,9,20,15];
%   num_duplicates = [0,2,4,0,3,2,0,0];
%   duplicated_elems = [];
%   % loopy way to do it
%   for idx = 1:length(elems)
%       duplicated_elems = [duplicated_elems, ...
%                           repmat(elems(idx), 1, num_duplicates(idx))];
%   end
%   disp(duplicated_elems)
%
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    assert(isvector(elems), 'elems should be a vector');
    assert(isvector(num_duplicates), 'num_duplicates should be a vector');
    assert(numel(elems) == numel(num_duplicates), ...
        'elems and num_duplicates should be of the same size');
    
    num_duplicates = num_duplicates(:);
    
    % remove elements which weren't replicated
    elems(num_duplicates <= 0) = [];
    num_duplicates(num_duplicates <= 0) = [];
    
    % if no duplication element is present in num_duplicates
    if isempty(num_duplicates)
        duplicated_elems = [];
        return;
    end
    
    duplicate_idxs = zeros(sum(num_duplicates), 1);
    % mark the starting locations
    duplicate_idxs([1; cumsum(num_duplicates(1:end-1))+1]) = 1;
    duplicate_idxs = cumsum(duplicate_idxs);
    duplicated_elems = elems(duplicate_idxs);
end

