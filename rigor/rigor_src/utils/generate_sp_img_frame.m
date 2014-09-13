% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [set, center_set] = generate_sp_img_frame(sp_seg, sp_sizes, ...
    frame_kind, thickness)
% frame_kind can be 'all', 'all_but_down', 'horiz', 'vert'.
%assert(strcmp(type,'pixels'));
if(nargin ==3)
    thickness = 1;
end

sp_seg_im_sz = size(sp_seg);

% the frame pixel indices (returned in sorted order)
pixel_set = frame_pixel_ids(sp_seg_im_sz(1), ...
    sp_seg_im_sz(2), thickness, ...
    frame_kind);

%             % replicate the border pixels to all other frames
%             im_pixels = prod(sp_seg_im_sz);
%             add_pixel_ids = repmat(0:length(obj.I)-1, ...
%                                    size(pixel_set,1),1) .* im_pixels;
%             pixel_set = repmat(pixel_set, length(obj.I), 1) + ...
%                         add_pixel_ids(:);

% get the superpixels which fall onto the frame
set = false(size(sp_sizes));
set(sp_seg(pixel_set)) = true;
if nargout > 1
% compute the centers for each SP in the frame
center_set = region_centroids_mex(uint32(sp_seg), ...
    max(sp_seg(:)))';
center_set = center_set(set,:);
end
end