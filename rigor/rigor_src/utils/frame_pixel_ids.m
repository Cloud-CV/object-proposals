% Copyright (C) 2010 Joao Carreira
%
% This code is part of the extended implementation of the paper:
%
% J. Carreira, C. Sminchisescu, Constrained Parametric Min-Cuts for Automatic Object Segmentation, IEEE CVPR 2010
%
% Modified:
%   @authors:     Ahmad Humayun
%   @contact:     ahumayun@cc.gatech.edu
%   @affiliation: Georgia Institute of Technology
%   @date:        Fall 2013 - Summer 2014

%function pixel_ids = frame_pixel_ids(nrows, ncols, width, custom)
% creates a frame whose external border has nrows and ncols, and width = 'width'
function seeds = frame_pixel_ids(nrows, ncols, width, custom)
    assert(width>=1);
    
    boundary_pixels_horiz_top = false(nrows, ncols);
    boundary_pixels_horiz_top(1:width, 1:end) = true;
    boundary_pixels_horiz_bottom = false(nrows, ncols);
    boundary_pixels_horiz_bottom(end-width+1:end, 1:end) = true;
    boundary_pixels_vert_left = false(nrows, ncols);
    boundary_pixels_vert_left(1:end, 1:width) = true;
    boundary_pixels_vert_right = false(nrows, ncols);
    boundary_pixels_vert_right(1:end, end-width+1:end) = true;

    if(strcmp(custom, 'horiz'))
        seeds = boundary_pixels_horiz_bottom | boundary_pixels_horiz_top;
    elseif(strcmp(custom, 'down'))
        seeds = boundary_pixels_horiz_bottom;
    elseif(strcmp(custom, 'up'))
        seeds = boundary_pixels_horiz_top;
    elseif(strcmp(custom, 'vert'))
        seeds = boundary_pixels_vert_left | boundary_pixels_vert_right;
    elseif(strcmp(custom, 'all_but_down'))
        seeds = boundary_pixels_horiz_top | boundary_pixels_vert_left | ...
                boundary_pixels_vert_right;
    elseif(strcmp(custom, 'all')) % whole frame
        seeds = boundary_pixels_horiz_top | ...
                boundary_pixels_horiz_bottom | ...
                boundary_pixels_vert_left | boundary_pixels_vert_right;
    else
        error('no such option');
    end
    
    seeds = seeds(:);
end