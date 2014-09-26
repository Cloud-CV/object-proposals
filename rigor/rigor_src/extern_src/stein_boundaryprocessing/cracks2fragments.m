function [fragments, junctions, neighbor_lookups] = cracks2fragments(crack_img, seg, isolation_check)
%
% [fragments, junctions, neighbor_lookups] = cracks2fragments(crack_img, seg, isolation_check)
% 

if(nargin<3)
    isolation_check = true;
end

[nrows,ncols] = size(crack_img);
JUNCTION_BIT = 5;

% Get a lookup table of where the image border is:
onborder = false(nrows,ncols);
onborder(:,[1 end]) = true;
onborder([1 end],:) = true;

num_neighbors_lookup = 4*ones(nrows,ncols);
num_neighbors_lookup([1 end],:) = 3;
num_neighbors_lookup(:,[1 end]) = 3;
num_neighbors_lookup([1 nrows end-nrows+1 end]) = 2;

% Neighbors: up, down, left, right
neighbor_offsets = [-1 1 -nrows nrows];

% for the up neighbor, i want to check its down bit (3); for the right
% neighbor, i want to check its left bit (4); etc...
check_bit_interior = [3 1 2 4];

% Figure out the valid neighbors on the borders
UP = 1; DOWN = 2; LEFT = 3; RIGHT = 4;
valid_border_neighbors = cell(nrows,ncols);
[valid_border_neighbors{1,:}]   = deal([DOWN LEFT RIGHT]);
[valid_border_neighbors{end,:}] = deal([UP LEFT RIGHT]);
[valid_border_neighbors{:,1}]   = deal([UP DOWN RIGHT]);
[valid_border_neighbors{:,end}] = deal([UP DOWN LEFT]);
valid_border_neighbors{1,1}     = [DOWN RIGHT];
valid_border_neighbors{1,end}   = [DOWN LEFT];
valid_border_neighbors{end,1}   = [UP RIGHT];
valid_border_neighbors{end,end} = [UP LEFT];

% % Find the junctions that aren't on the image border
junction_map = bitget(crack_img, JUNCTION_BIT);
junction_index = find(junction_map);
num_junctions = length(junction_index);

junction_map = double(junction_map);
junction_map(junction_index) = 1:num_junctions;
junction_fragmentlist = cell(1,num_junctions);
fragment_junctionlist = {};
fragment_segments     = {};
segment_fragments     = cell(1,max(seg(:)));

[junction_y,junction_x] = ind2sub([nrows ncols], junction_index);
junctions = [junction_x(:)+0.5 junction_y(:)+0.5];

%% Fragment Chaining
not_in_fragment = true(nrows,ncols);

fragment_indices = zeros(1,nrows*ncols);
fragment_ctr = 0;
fragments = {};

% % Randomize the order we go through the starting junctions (mainly for
% % debug/display purposes):
% rand_index = randperm(num_junctions);
% for(i_rand=1:num_junctions)
%     i = rand_index(i_rand);
for(i = 1:num_junctions)

    % get the neighbors of the starting junction that have not already been
    % made part of another fragment and whose orientation/shape match this
    % junction
    if(~onborder(junction_index(i)))
        junction_neighbors = junction_index(i)+neighbor_offsets;
        check_bit = check_bit_interior;
    else
        junction_neighbors = junction_index(i)+neighbor_offsets(valid_border_neighbors{junction_index(i)});
        check_bit = check_bit_interior(valid_border_neighbors{junction_index(i)});
    end

    neighbor_bits = bitget(crack_img(junction_neighbors), check_bit);
    which_junction_neighbors = find(neighbor_bits & not_in_fragment(junction_neighbors)); % ...
%         & ~onborder(junction_neighbors));% & ~junction_map(junction_neighbors));

    % remove any neighbors that are themselves junctions and have a lower
    % index than the current starting junction.  a single-crack-long
    % fragment has already been chained between these two junctions in this
    % case, so we don't need to do it again.
    which_junction_neighbors( junction_map(junction_neighbors(which_junction_neighbors)) & ...
        junction_neighbors(which_junction_neighbors) < junction_index(i) ) = [];

    % create a fragment starting from this junction and heading off along
    % each available neighbor
    for(j = 1:length(which_junction_neighbors))

        % in case we just closed a loop, don't start marching back out
        % around the same loop in the opposite direction:
        if(not_in_fragment(junction_neighbors(which_junction_neighbors(j))))

            % prevent us from coming right back to the starting junction on
            % the next step
            not_in_fragment(junction_index(i)) = false;

            fragment_ctr = fragment_ctr + 1;

            junction_fragmentlist{i}(end+1) = fragment_ctr;
            fragment_junctionlist{fragment_ctr} = i;

            fragment_length = 1;
            fragment_indices(1) = junction_index(i);

            % record the segmentation numbers on either side of this 
            % fragment, store as [leftseg rightseg]
            if(~onborder(junction_index(i)))
                step_dir = which_junction_neighbors(j);
            else
                step_dir = valid_border_neighbors{junction_index(i)}(which_junction_neighbors(j));
            end
            switch(step_dir)
                case(1) % about to move UP
                    fragment_segments{fragment_ctr} = [seg(junction_index(i)) seg(junction_index(i)+nrows)];
                case(2) % about to move DOWN
                    fragment_segments{fragment_ctr} = [seg(junction_index(i)+1+nrows) seg(junction_index(i)+1)];
                case(3) % about to move LEFT
                    fragment_segments{fragment_ctr} = [seg(junction_index(i)+1) seg(junction_index(i))];
                case(4) % about to move RIGHT
                    fragment_segments{fragment_ctr} = [seg(junction_index(i)+nrows) seg(junction_index(i)+1+nrows)];
                otherwise
                    error('Invalid neighbor chosen???')
            end

            % record this fragment as bounding each of its two segments
            for(k=1:2)
                segment_fragments{fragment_segments{fragment_ctr}(k)}(end+1) = fragment_ctr;
            end

            neighbors = junction_neighbors;
            which_neighbors = which_junction_neighbors(j);
            while(~isempty(which_neighbors))
                % add current position to fragment
                fragment_length = fragment_length + 1;
                fragment_indices(fragment_length) = neighbors(which_neighbors);

                % once we've gone more than one step from the start, re-enable
                % the possibility of ending up there, in case of a closed
                % fragment around an isolated segment
                if(fragment_length==3)
                    not_in_fragment(junction_index(i)) = true;
                end

                % if we've reached another junction, add that junction to this
                % fragment and stop
                if(junction_map(neighbors(which_neighbors)))
                    % Don't add this fragment if this is a closed loop and
                    % we already have it listed as a member of this
                    % junction
                    if(neighbors(which_neighbors) ~= junction_index(i))
                        junction_fragmentlist{junction_map(neighbors(which_neighbors))}(end+1) = fragment_ctr;
                    end
                    fragment_junctionlist{fragment_ctr}(2) = junction_map(neighbors(which_neighbors));

                    break;
                end

                % Otherwise, mark this position as being part of a fragment and
                % continue chaining
                not_in_fragment(fragment_indices(fragment_length)) = false;

                % get matching neighbors from this point that aren't already
                % used in another fragment
                crnt = fragment_indices(fragment_length);
                if(~onborder(crnt))
                    neighbors = crnt + neighbor_offsets;
                    check_bit = check_bit_interior;
                else
                    neighbors = crnt + neighbor_offsets(valid_border_neighbors{crnt});
                    check_bit = check_bit_interior(valid_border_neighbors{crnt});
                end
                neighbor_bits = bitget(crack_img(neighbors), check_bit);
                which_neighbors = find(neighbor_bits & not_in_fragment(neighbors)); % & ~onborder(neighbors));

            end

            % Create the fragment from the list of indices.  Offset it by 0.5
            % pixels in either direction to put it in image coordinates.
            [y,x] = ind2sub([nrows ncols], fragment_indices(1:fragment_length));
            fragments{fragment_ctr} = [x(:)+0.5 y(:)+0.5];

            % If this fragment didn't end at a junction (but instead at the
            % image border), add a "junction" for the end point:
            if(numel(fragment_junctionlist{fragment_ctr})==1)
                num_junctions = num_junctions + 1;
                junctions(num_junctions,:) = fragments{fragment_ctr}(end,:);
                fragment_junctionlist{fragment_ctr}(2) = num_junctions;
                junction_fragmentlist{num_junctions} = fragment_ctr;
            end


        end

    end
    
    % Allow other fragments to end up at this junction (this _should_
    % already have been set back to true in most cases, but just in
    % case...)
    not_in_fragment(junction_index(i)) = true;
end

%% Handle isolated regions
if(isolation_check)

    % Look for any segments that have not had any fragments used yet.  They
    % must be surrounded entirely by one other segment meaning their boundary
    % has no junctions.  We need
    % to add a fragment for that boundary (and some junctions) to our list.
    used_segments = vertcat(fragment_segments{:});
    used_segments = unique(used_segments(:));
    num_segments = max(seg(:));
    unused_segments = true(1,num_segments);
    unused_segments(used_segments) = false;
    unused_segments = find(unused_segments);
    if(~isempty(unused_segments))
        stats = regionprops(seg, 'PixelIdxList');
        segment_indices = {stats.PixelIdxList};

        isolated_seg = zeros(size(seg));
        for k = 1:numel(unused_segments)
            isolated_seg(segment_indices{unused_segments(k)}) = k;
        end
        num_isolated_seg = numel(unused_segments);
        %isolated_seg(vertcat(segment_indices{unused_segments})) = true;
        %[isolated_seg, num_isolated_seg] = bwlabel(isolated_seg, 8);

        % Put a false junction on the border of each isolated segment:
        for(i=1:num_isolated_seg)
            % Get the cracks for this isolated segment
            isolated_cracks = seg2cracks(isolated_seg==i);

            % Put a false junction indicator on the border of the isolated
            % segment
            crack_index = find(isolated_cracks>0);
            isolated_cracks(crack_index(1)) = bitset(isolated_cracks(crack_index(1)), JUNCTION_BIT);

            % Chain the fragments around this isolated segment
            [temp_fragments, temp_junctions, temp_neighbor] = ...
                cracks2fragments(isolated_cracks, seg, false);

            % Concatenate the results with the existing results, adjusting
            % fragment and junction numbering as necessary
            fragments = [fragments temp_fragments];
            junctions = [junctions; temp_junctions];
            for(j=1:numel(temp_neighbor.junction_fragmentlist))
                temp_neighbor.junction_fragmentlist{j} = temp_neighbor.junction_fragmentlist{j} + fragment_ctr;
            end
            junction_fragmentlist = [junction_fragmentlist temp_neighbor.junction_fragmentlist];
            for(j=1:numel(temp_neighbor.fragment_junctionlist))
                temp_neighbor.fragment_junctionlist{j} = temp_neighbor.fragment_junctionlist{j} + num_junctions;
            end
            fragment_junctionlist = [fragment_junctionlist temp_neighbor.fragment_junctionlist];

            fragment_segments = [fragment_segments temp_neighbor.fragment_segments];
            update_segments = ~cellfun('isempty', temp_neighbor.segment_fragments);
            for(j=find(update_segments))
                segment_fragments{j} = [segment_fragments{j} temp_neighbor.segment_fragments{j}+fragment_ctr];
            end
            
            % Don't want to update these too soon!
            fragment_ctr = fragment_ctr + numel(temp_fragments);
            junction_ctr = num_junctions + size(temp_junctions,1);

        end

    end

end

%% Output 
neighbor_lookups.junction_fragmentlist = junction_fragmentlist;
neighbor_lookups.fragment_junctionlist = fragment_junctionlist;
neighbor_lookups.fragment_segments     = fragment_segments;
neighbor_lookups.segment_fragments     = segment_fragments;
       

% Compute edge adjacency info
num_fragments = fragment_ctr;
FORWARD = 2; REVERSE = 1;
directed_neighbors = cell(2*num_fragments,1);
for(i=1:num_fragments)
    % Get forward neighbors
    directed_neighbors{i} = get_neighbors(i, neighbor_lookups, FORWARD, num_fragments);
    
    % Get reverse neighbors
    directed_neighbors{i+num_fragments} = get_neighbors(i, neighbor_lookups, REVERSE, num_fragments);
    
end

neighbor_lookups.directed_neighbors = directed_neighbors;

% DEBUG CODE:
% % Check that we're not still having the problem where a fragment has the
% % same superpixel listed on both sides.
% temp = vertcat(fragment_segments{:});
% if(any(temp(:,1)==temp(:,2)))
%     warning('At least one fragment has the same superpixel listed for left and right!')
%     keyboard
% end

return;


%% Helper: Find directed neighbors
function neighbors = get_neighbors(fragment, neighbor_data, direction, num_fragments)

% direction==2 -> forward
% direction==1? -> reverse

% Get all the foward neighbors for this fragment:
junction = neighbor_data.fragment_junctionlist{fragment}(direction);
neighbors = neighbor_data.junction_fragmentlist{junction};
neighbors(neighbors==fragment) = [];

if(~isempty(neighbors))
    % Any neighbors that connect to this in the wrong direction should be
    % referenced to the reverse fragment
    neighbor_junctions = vertcat(neighbor_data.fragment_junctionlist{neighbors});
    to_reverse = (neighbor_junctions(:,2)==junction);
    neighbors(to_reverse) = neighbors(to_reverse) + num_fragments;
end
    
    