function [fragments, junctions, neighbor_data, seg, avg_seg_colors, ...
    polyfragments, poly_params] = seg2fragments(seg, img, min_area, order)
%
% [fragments, junctions, neighbor_data, new_seg, avg_seg_colors, ...
%  <polyfragments>, <poly_params>] = seg2fragments(seg, img, min_area, <order>)
% 
%  Finds the boundary fragments for an oversegmentation of an image:
%
%  (1) Takes in an over-segmentation labeling (with labels 1:N),
%  (2) Fills any pixels with a label of zero with the neighboring label 
%      that has the most similar color value in the original RGB color 
%      image 'img', 
%  (3) Cleans up segments which have a single pixel jutting diagonally off
%      of a corner somewhere, by reassigning these offending pixels to the
%      neighboring segment with the most similar color (as in (2)).
%  (4) Breaks diagonal-only connected segments into two new segments. 
%  (5) Merges segments that are too small with a neighbor with the most 
%      similar average color, and 
%  (6) Chains fragments along the boundaries between segments, stopping at 
%      junctions and image borders.  
%
%  Returns the fragments as a cell array of [Mx2] matrices which contain 
%  the M (x,y) coordinates of of each fragment's constituent elements, the 
%  fragment neighbor information (see below for details), and the new 
%  (filled-in / merged) segmentation.
%
%  'neighbor_data' is a struct with two fields:
%   - 'junction_fragmentlist': a list which contains for each junction an
%                              array of indices of the fragments that meet 
%                              there
%   - 'fragment_junctionlist': a list which contains for each fragment the
%                              indices of the junctions which bound it
%   - 'fragment_segments': a list which contains for each fragment the ID
%                          numbers of the segments found to the left and
%                          right of that fragment, stored [left right].
%   - 'segment_fragments': a list which contains for each segment the index
%                          of the fragments that border it
%
%  Thus, the indices of fragment i's neighbors on one end can be found by:
%    junction_fragmentlist{fragment_junctionlist{i}(1)}
%
%  If requested, also fits polynomials of degree 'order' to each fragment
%  and returns those as well (and their parameters).
%

% DEPENDENCIES:
%  - RGB2Lab.m
%  - cracks2fragments.m
%  - fill_in_segmentation.m
%  - fit_curves.m
%    - fit_poly_to_fragment.m
%  - remove_small_segments.m
%  - seg2cracks.m
% [- drawedges.m (will use it if available, not a problem if not)]
    
[nrows, ncols] = size(seg);

% Convert the image to Lab space so that color distances used below are
% more meaningful
if ~isempty(img)
    img_lab = RGB2Lab(img);
end

while (any(seg(:)==0))
    seg = fill_in_segmentation(img, seg, 0, 4);
end

num_segments = max(seg(:));

% Find locations where there's a pixel jutting off diagonally from  a 
% corner of a segment.  We want to remove those and attach them to the 
% nearest-colored 4-connected neighbor.
% Note: this is actually redundant since this would also be covered below,
% but it's much faster to remove the simple singleton stragglers like this
% first (since it requires fewer calls to bwselect).
% stragglers = find( seg~=seg(:,[2:end end]) & seg~=seg(:,[1 1:end-1]) & ...
%     seg~=seg([2:end end],:) & seg~=seg([1 1:end-1],:) );
% if(any(stragglers(:)))
%     corner_neighbor_offsets = [-1-nrows -1+nrows 1-nrows 1+nrows];
%     
%     for(i=1:length(stragglers))
%         % if the straggler was diagonnally connecting >=2 larger pieces of
%         % this segment, we need to re-label all but one of them to avoid
%         % inadvertantly splitting a segment into multiple pieces by
%         % removing the straggler
%         [y,x] = ind2sub([nrows ncols], stragglers(i));
%         corner_x = x + [-1 1 1 -1];
%         corner_y = y + [-1 -1 1 1];
%         out_of_bounds = find(corner_x<1 | corner_x>ncols | corner_y<1 | corner_y>nrows);
%         corner_x(out_of_bounds) = [];
%         corner_y(out_of_bounds) = [];
%         corner_neighbors = sub2ind([nrows ncols], corner_y, corner_x);
%         to_relabel = find( seg(corner_neighbors)==seg(stragglers(i)) );
%         if(length(to_relabel)>=2)
%             bw_img = seg==seg(stragglers(i));
%             for(j = 1:length(to_relabel))
%                 num_segments = num_segments+1;
%                 seg(bwselect(bw_img,corner_x(to_relabel(j)),corner_y(to_relabel(j)),4)) = num_segments;
%             end
%         end
%     end
%     
%     % Now actually get rid of the stragglers by setting them to zero and
%     % filling them in:
%     seg(stragglers) = 0;
%     seg = fill_in_segmentation(img, seg, 0, 4);
%             
% end

% Convert the segmentation to a crack image.  Note that we need this for
% the next step, even if we have to end up re-doing it later if small
% segments get removed.
cracks = seg2cracks(seg);

% Find locations where a single segment narrows to a singe-pixel diagonal
% connection.  We want to split such locations into two segments.
down_right_splits = find(cracks==15 & seg==seg([2:end end],[2:end end]));
down_left_splits  = find(cracks==15 & seg(:,[2:end end])==seg([2:end end],:));
[r,c] = ind2sub([nrows ncols], down_right_splits);
for(i=1:length(down_right_splits))
    % Need to set _both_ of the resulting segments after the split to new
    % ID numbers to avoid inadvertantly forming a non-contiguous segment
    % later... (argh, twice as many bwselect calls!)
    temp = seg==seg(down_right_splits(i));
    num_segments = num_segments+1;
    seg(bwselect(temp,c(i),r(i),4)) = num_segments;
    num_segments = num_segments+1;
    seg(bwselect(temp,c(i)+1,r(i)+1,4)) = num_segments;
end
[r,c] = ind2sub([nrows ncols], down_left_splits);
for(i=1:length(down_left_splits))
    temp = seg==seg(r(i),c(i)+1);
    num_segments = num_segments+1;
    seg(bwselect(temp,c(i)+1,r(i),4)) = num_segments;
    num_segments = num_segments+1;
    seg(bwselect(temp,c(i),r(i)+1,4)) = num_segments;    
end

if(nargin < 3 || isempty(min_area))
    min_area = 0;
end

if min_area > 0
    [seg, avg_seg_colors] = remove_small_segments(seg, img_lab, min_area);
end

% Assuming any segments were removed, we'll need to update the crack info
cracks = seg2cracks(seg);

try
    [fragments, junctions, neighbor_data] = cracks2fragments(cracks, seg);
catch
    disp('warning: no isolation check');
    [fragments, junctions, neighbor_data] = cracks2fragments(cracks, seg, 0);
end

if(nargout>=5 || nargout==0)
    if(nargin < 4)
        order = 3;
    end
    
    [polyfragments, poly_params] = fit_curves(fragments, order);
end

if(nargout==0)
    figure(gcf)
    subplot 121, hold off
    imagesc(img), axis image, hold on
    title('Segment Borders')
    
    subplot 122, hold off
    imagesc(img), axis image, hold on
    title(['Polynomial Fits to Fragments (order=' num2str(order)])
    
    if(exist('file', 'drawedges'))
        subplot 121, drawedges(fragments, 'rand');
        subplot 122, drawedges(polyfragments, 'rand');
    else
        subplot 121
        for(i=1:length(fragments))
            plot(fragments{i}(:,1), fragments{i}(:,2), 'r', 'LineWidth', 2);
        end
        subplot 122
        for(i=1:length(polyfragments))
            plot(polyfragments{i}(:,1), polyfragments{i}(:,2), 'r', 'LineWidth', 2);
        end
    end    
end
    