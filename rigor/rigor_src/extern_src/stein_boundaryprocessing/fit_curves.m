function [curve_list, param_list, error_list, T] = fit_curves(linked_edges, order)
%
%[curve_list, param_list, error_list, T] = fit_curves(linked_edges, order)
% 
% Fit a polynomial curve of specified order to each edge chain in
% linked_edges list. (Defaults to quadratic (order=2).)
% T is a list of arc-length parameters raised to the appropriate order
% for each fitted polynomial, s.t.,  curve_list{i} = T{i} * params_list{i}

if(nargin==1)
    order = 2; % default to quadratic
end

% Handle case that a single set of x/y coords was passed in, not a list.
single_input = ~iscell(linked_edges);
if(single_input)
    linked_edges = {linked_edges};
end

% Initialize empty lists for the output:
curve_list = cell(size(linked_edges));
T = cell(size(linked_edges));

if(nargout>=2)
    param_list = cell(size(linked_edges));
    if(nargout>=3)
        error_list = cell(size(linked_edges));
    end
end

% Go through each set of points and fit a curve of the appropriate order
for(i = 1:length(linked_edges))
    
    % Fit the lowest order polynomial possible
    for o = 1:order
        [curve_list{i}, params, errors, T{i}] = fit_poly_to_fragment(linked_edges{i}, order);
        
        total_error = mean(sqrt(sum(errors.^2, 2)));
        
        if (total_error < 1)
            break;
        end
    end
    
    if(nargout>=2)
        param_list{i} = params;
        if(nargout>=3)
            error_list{i} = errors;
        end
    end
end

if(single_input)
    curve_list = curve_list{1};
    if(nargout>=2)
        error_list = error_list{1};
        if(nargout>=3)
            param_list = param_list{1};
        end
    end
end
    
    
    
   