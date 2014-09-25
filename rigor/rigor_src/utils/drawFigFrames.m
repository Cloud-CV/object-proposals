% Used for printing and displaying image
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [ varargout ] = drawFigFrames( varargin )
% evaluate function according to the number of inputs and outputs

    if nargout(varargin{1}) > 0
        [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
end

function [fig_info] = init_fig(frame_sz, varargin)
    addpath_export_fig();
    
    screen_sz = get(0,'ScreenSize');
    fig_info.fg_h = figure('units', 'pixels', 'position', ...
        [screen_sz([3 4])-frame_sz([2 1])-40 frame_sz([2 1])], ...
        'paperpositionmode', 'auto', varargin{:});
    fig_info.ax_h = axes('Parent',fig_info.fg_h);
end

function h = imshow_fig(frame, fig_info, varargin)
    h = imshow(frame, 'Parent',fig_info.ax_h, ...
        'InitialMagnification','fit', 'Border','tight', varargin{:});
%     truesize;
end

function h = imagesc_fig(frame, fig_info, varargin)
    h = imagesc(frame, 'Parent',fig_info.ax_h, varargin{:});
    adjust_ax(fig_info);
end

function h = image_fig(frame, fig_info, varargin)
    h = image(frame, 'Parent', fig_info.ax_h, varargin{:});
    adjust_ax(fig_info);
end

function holdonoff(on_off, fig_info)
    hold(fig_info.ax_h, on_off);
end

function fg_h = get_fig_h(fig_info)
    fg_h = fig_info.fg_h;
end

function ax_h = get_ax_h(fig_info)
    ax_h = fig_info.ax_h;
end

function export_fig_only(im_filepath, fig_info)
    adjust_ax(fig_info);
%     set(fig_info.ax_h, 'Units','pixels','Position',[200 200 c r]); 
    export_fig(im_filepath, '-a1', fig_info.fg_h);
%     set(gca,'Position',[0 0 1 1]);  %# Modify axes size
end

function export_fig_and_clear(im_filepath, fig_info)
    export_fig_only(im_filepath, fig_info);
    delete(get(fig_info.ax_h, 'children'));
end

function adjust_ax(fig_info)
    set(fig_info.ax_h, 'Units','normalized', ...
        'position', [0 0 1 1], 'visible', 'off');
end

function close_fig(fig_info)
    delete(fig_info.ax_h);
    close(fig_info.fg_h);
end

function addpath_export_fig(extern_dir)
    % get export_fig in the path
    if exist('extern_dir', 'var') == 0
        extern_dir = 'C:\Users\Administrator\Documents\MATLAB\Rigor_untouched\extern_src';
    end
    addpath(fullfile(extern_dir, 'utils', 'export_fig'));
end
