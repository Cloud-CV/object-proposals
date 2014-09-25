function [new_seg, segment_colors] = remove_small_segments(seg, img, min_area, reorder);
%
% [new_seg] = remove_small_segments(seg, img, min_area, <reorder>);
%
%  Remove segments below a minimum size, assigning them to a neighbor
%  segment with the most similar average color.
%
%  If reorder is true (default), the segmentation ID's are re-ordered to
%  remove gaps remaining from removed segment ID's.
%

if(nargin < 4)
    reorder = true;
end

[nrows,ncols] = size(seg);
onborder = false(nrows,ncols);
onborder([1 end],:) = true;
onborder(:,[1 end]) = true;

stats = regionprops(seg, 'PixelIdxList', 'Area');
all_indices = {stats(:).PixelIdxList};
areas = [stats(:).Area];
num_segments = length(areas);

% Compute the average color of each segment
segment_colors = cell(num_segments,1);
for(i=1:num_segments)
    if(areas(i)>0)
        color_indices = [all_indices{i} all_indices{i}+nrows*ncols all_indices{i}+2*nrows*ncols];
        segment_colors{i} = mean(img(color_indices), 1);
    end
end
        
% Only use 4-connected neighbors b/c we can end up joining segments that
% are only connected by a single diagonal connection (which we to great
% pains to remove before)
neighbor_offsets = [-1 1 -nrows nrows];% -1-nrows -1+nrows 1-nrows 1+nrows];

new_seg = seg;


[sorted_areas, sort_index] = sort(areas);
too_small = find(sorted_areas<min_area & sorted_areas>0);

for(i = too_small)
    segment_indices = all_indices{sort_index(i)};  %find(new_seg==sort_index(i));

    % make sure this segment hasn't already had a smaller segment merged
    % with it, making it big enough to pass the threshold
    if(~isempty(segment_indices) && length(segment_indices)<min_area)
        % Find this segment's neighbors, being careful at boundaries
        [origy, origx] = ind2sub([nrows ncols], segment_indices);
        y = [origy+1 ; origy-1 ; origy   ; origy];
        x = [origx   ; origx   ; origx+1 ; origx-1];
        neighbor_indices = y + (x-1)*nrows;
        %neighbor_indices = segment_indices*ones(1,4) + ones(length(segment_indices),1)*neighbor_offsets;       
        %[y,x] = ind2sub([nrows ncols], neighbor_indices);
        neighbor_indices(x<1 | x>ncols | y<1 | y>nrows) = [];
        neighbors = unique(new_seg(neighbor_indices));
        neighbors(neighbors==sort_index(i)) = [];

%         % Compute this segment's average color if not already stored
%         if(isempty(segment_colors{sort_index(i)}))
%             color_indices = [segment_indices segment_indices+nrows*ncols segment_indices+2*nrows*ncols];
%             segment_colors{sort_index(i)} = mean(img(color_indices), 1);
%         end

        % Compute the neighbor segments' average colors if not already
        % stored
        num_neighbors = length(neighbors);
%         neighbor_indices = cell(1,num_neighbors);
%         for(j=1:num_neighbors)
%             if(isempty(segment_colors{neighbors(j)}))
%                 neighbor_indices(j) = all_indices(neighbors(j)); % find(new_seg==neighbors(j));
%                 color_indices = [neighbor_indices{j}(:) neighbor_indices{j}(:)+nrows*ncols neighbor_indices{j}(:)+2*nrows*ncols];
%                 segment_colors{neighbors(j)} = mean(img(color_indices), 1);
%             end
%         end

        % Lookup the neighbors' colors
        neighbor_colors = vertcat(segment_colors{neighbors});

        % Compute the distance between this segment's average color and the
        % neighbors' colors, and find the one with the most similar color.
        this_seg_color = ones(num_neighbors,1)*segment_colors{sort_index(i)};
        color_dist = sum( (this_seg_color-neighbor_colors).^2 , 2);
        [min_dist, which_neighbor] = min(color_dist);

        % Make this segment part of that neighbor:
        new_seg(segment_indices) = neighbors(which_neighbor);
        all_indices{sort_index(i)} = [];
        all_indices{neighbors(which_neighbor)} = [all_indices{neighbors(which_neighbor)}; segment_indices];
        
        % Update the neighbor segment's avg. color now that it has grown:
        segment_area = length(segment_indices);
        neighbor_area = length(all_indices{neighbors(which_neighbor)});
        total_area =  segment_area + neighbor_area;
        segment_colors{neighbors(which_neighbor)} = ...
            (segment_area*segment_colors{sort_index(i)} + ...
            neighbor_area*segment_colors{neighbors(which_neighbor)}) / total_area;
    end
end

if(reorder)
    % Re-label the segmentation regions so there are no gaps in the
    % numbering (i.e. no segments with zero area)
    
    stats = regionprops(new_seg, 'Area');
    areas = [stats.Area];
    
    to_keep = double(areas > 0);
    shifts = zeros(1,numel(areas));
    shifts(areas==0) = 1;
    shifts = cumsum(shifts);
    new_seg = new_seg - shifts(new_seg);
    

    % This is Derek's original method, but it seems to still leave some
    % zero-area regions that the above catches.
% %     nseg = max(new_seg(:));  % i think this will cause a problem if the max in new_seg is _less_ than the max in seg   
%     diffs = unique(seg(seg~=new_seg));
%     shifts = zeros(1, num_segments);  shifts(diffs) = 1;  shifts = cumsum(shifts);
%     new_seg = new_seg - shifts(new_seg);
    
    % Also get rid of the segment_colors that were deleted
    segment_colors(areas==0) = [];
end

if(nargout==0)
    figure
    subplot 131, imagesc(seg), axis image
    title([num2str(length(unique(seg(:)))) ' Segments Originally'])
    subplot 132, imagesc(new_seg), axis image
    title([num2str(length(unique(new_seg(:)))) ' Segments After Merging'])
    subplot 133, imagesc(seg~=new_seg), axis image
    title('Changes')
end
    
return;