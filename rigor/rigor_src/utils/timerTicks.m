% Simulates a progress bar in MATLAB. At the end prints the total time
% elapsed.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [ varargout ] = timerTicks( varargin )
% evaluate function according to the number of inputs and outputs
    if nargout(varargin{1}) > 0
        [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
end


function [ ticker_info ] = init_ticker(varargin)
    ticker_info.num_markers = 20;
    for param_idx = 1:2:length(varargin)
        if strcmpi(varargin{param_idx}, 'num_markers')
            ticker_info.num_markers = varargin{param_idx+1};
        end
    end
    ticker_info.last_mark = 1;
    fprintf(1, '[');
    
    ticker_info.tic_id = tic;
end


function [ ticker_info ] = tick(ticker_info, curr_iter, total_iters)
    prcnt_done = (curr_iter / total_iters) * 100;
    if floor(prcnt_done/(100/ticker_info.num_markers)) > ...
            ticker_info.last_mark
        fprintf(1, '.');
        ticker_info.last_mark = ...
            floor(prcnt_done/(100/ticker_info.num_markers));
    end
end


function [ ticker_info ] = fin_ticker(ticker_info, info_str)
    ticker_info.total_time = toc(ticker_info.tic_id);
    fprintf(1, '] ::: %s computation time %.2fs\n', info_str, ...
        ticker_info.total_time);
end