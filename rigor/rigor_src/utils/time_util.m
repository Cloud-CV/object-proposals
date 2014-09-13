function time_util(seg_obj, t_var, t_start, append_time, do_disp)
%TIME_UTIL used to note the time taken. 
% t_var: which variable this elapse time needs to be stored in
% t_start: gives the time when the clock was started
% append_time: 1 if the time needs to be appended or just replaced
% do_disp: 1 if the time needs to be displayed on console
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    t_elapsed = toc(t_start);
    if append_time
        seg_obj.timings.(t_var) = [seg_obj.timings.(t_var), t_elapsed];
    else
        seg_obj.timings.(t_var) = t_elapsed;
    end
    
    if do_disp
        fprintf('%.2fs\n', t_elapsed);
    end
end

