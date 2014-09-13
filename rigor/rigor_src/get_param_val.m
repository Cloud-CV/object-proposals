function params_struct = get_param_val(params_struct, direct_params, ...
                                       field_name, default_val)
% used by all params_* files to get the value of a particular parameter
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    if ~isfield(params_struct, field_name)
        params_struct.(field_name) = default_val;
    end
    
    % if user gave the parameter directly, then override everything else
    if any(strcmpi(direct_params, field_name))
        % the first specified value is picked
        param_pos = find(strcmpi(direct_params, field_name), 1, 'first');
        params_struct.(field_name) = direct_params{param_pos + 1};
    end
end