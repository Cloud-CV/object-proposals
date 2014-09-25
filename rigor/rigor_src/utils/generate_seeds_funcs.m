% Function which computes seeds for an image, given parameters.
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function [ varargout ] = generate_seeds_funcs( varargin )
% evaluate seed functions
    if nargout(varargin{1}) > 0
        [varargout{1:nargout(varargin{1})}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
end

% function [sets] = generate_img_grid(I, type, shape_coords, mn, mapAggs)
% % generate seeds centered around evenly spaced grid locations. The number
% % of grid locations per image is defined [mn] in the horizontal and 
% % vertical direction. The [shape_coords] defines what would be the actual 
% % pixels in each set of seed locations. So this function would return 
% % [prod(mn)*length(I)] number of seed [sets], where each seed set would 
% % have the same number of pixels as [shape_coords] / [size(shape_coords,1)]
% 
%     if(sum(mn) == 0)
%         sets = {};
%         return;
%     end
%     
%     n_rows = size(I{1}, 1);
%     n_cols = size(I{1}, 2);
% 
%     centers = generate_centers(n_rows, n_cols, shape_coords, mn);
%     
%     coord_sets = cell(size(centers,1), 1);
%     sets = coord_sets;
%     
%     pixel_sets = create_seed_coords([n_rows n_cols], centers, ...
%                                     shape_coords);
%     
%     % now convert to actual variable ids
%     if(strcmp(type,'pixels'))
%         sets = pixel_sets;
%     else
%         aggs = mapAggs(type);
%         % quite slow, should try improving
%         for i=1:length(pixel_sets)
%             p = pixel_sets{i};
%             for j=1:length(aggs)
%                 agg = aggs{j};
%                 inters = intersect(agg, p);
%                 if(~isempty(inters))
%                     sets{i} = [sets{i} j];
%                 end
%             end
%         end
%     end
% 
%     % show_seeds(I{1}, sets, true);
% 
%     % replicate for all frames
%     sets = cellfun(@(c) repmat(c, [length(I), 1]), sets, ...
%                    'UniformOutput', false);
%     sets = sets(:);
% end

function [sets] = generate_sp_img_grid(sp_seg, shape_coords, mn, ...
                                       sp_seg_szs, min_seed_frac_sp)
    if(sum(mn) == 0)
        sets = {};
        return;
    end
    
    sp_seg_im_sz = size(sp_seg);

    centers = generate_centers(sp_seg_im_sz(1), sp_seg_im_sz(2), ...
                               shape_coords, mn);
    pixel_sets = create_seed_coords(sp_seg_im_sz, centers, shape_coords);
    
    % convert pixel sets to superpixel sets, by finding which superpixels
    % overlap with the pixels given in each set
    [sets] = pixel_set_to_sp_set(pixel_sets, sp_seg, sp_seg_szs, ...
                                 min_seed_frac_sp);
end

function [sets] = generate_sp_user(sp_seg, shape_coords, centers, ...
                                   sp_seg_szs, min_seed_frac_sp)
    sp_seg_im_sz = size(sp_seg);

    pixel_sets = create_seed_coords(sp_seg_im_sz, centers, shape_coords);
    
    % convert pixel sets to superpixel sets, by finding which superpixels
    % overlap with the pixels given in each set
    [sets] = pixel_set_to_sp_set(pixel_sets, sp_seg, sp_seg_szs, ...
                                 min_seed_frac_sp);
end

function [sets] = generate_sp_seeds_superpixels(sp_data, I, ...
                                                superpixel_method, ...
                                                min_seed_frac_sp, varargin)
% generates seeds which are close to some superpixel segments

    superpixel_func = str2func(superpixel_method);
    
    % generate pixel sets by a superpixel method
    pixel_sets = superpixel_func(sp_data, I, varargin{:});
    
    % convert pixel sets to superpixel sets, by finding which superpixels
    % overlap with the pixels given in each set
    [sets] = pixel_set_to_sp_set(pixel_sets, sp_data.sp_seg, ...
                                 sp_data.sp_seg_szs, min_seed_frac_sp);
end

function [sets] = sp_seeds_caller(sp_data, I, shape_coords, n)
% This method is similar to felzenszwalb_seeds_caller, except that it uses
% the superpixels already computed. It creates sets of pixel seeds centered 
% around the centroids of some  selected superpixels. The selected 
% superpixels are the ones whose centroids is closest to one of the 
% [prod(n)] grid locations.

    assert(~isempty(sp_data), 'No superpixel precomputed info');
    
    % Find the size of each superpixel - order them by size
    n_p = sp_data.sp_seg_szs;
    [val, size_order] = sort(n_p, 'descend');

    % compute the centroid for each label (superpixel)
    centroids = sp_data.sp_centroids;
    
    % select the superpixels which are closest to [prod(n)] equally spaced 
    % grid locations (does nothing with size_order)
    id_selected = select_around_grid(I, sp_data.sp_seg, centroids, n, ...
                                     size_order);
    id_selected = unique(id_selected);

    % find the centroid of the selected superpixels
    centroids = round(centroids(id_selected,:));
    
    % create the sets of pixel seeds centered around the centroids of the 
    % selected superpixels
    sets = create_seed_coords([size(I,1) size(I,2)], centroids, shape_coords);
end

function [sets] = felzenszwalb_seeds_caller(sp_data, I, shape_coords, n, ...
                                            varargin)
% Creates the sets of pixel seeds centered around the centroids of some 
% selected superpixels. The selected superpixels are the ones whose
% centroids is closest to one of the [prod(n)] grid locations.

    % sigma - scalar parameter on smoothing kernel to use prior to
    %         segmentation.
    sigma_k = 0.1;
    % sigma_k = 0.001;

    % k - scalar parameter on prefered segment size.
    k = 400;

    % min_sz - scalar indicating the minimum number of pixels per 
    %          segment.
    min_sz = 100;
    
    % check if any optional arguments were passed
    for idx = 1:2:length(varargin)
        if strcmpi(varargin{idx}, 'sigma_k')
            sigma_k = varargin{idx+1};
        elseif strcmpi(varargin{idx}, 'k')
            k = varargin{idx+1};
        elseif strcmpi(varargin{idx}, 'min_sz')
            min_sz = varargin{idx+1};
        else
            error('generate_seeds_funcs:felzenszwalb_seeds_caller', ...
                'Invalid argument ''%s'' passed', varargin{idx});
        end
    end
    
    sets = {};

    the_min = prod(n);

    if(sum(n) == 0)
        return;
    end

    counter = 0;
    
    % iterate till you get a superpixel segmentation with atleast [the_min]
    % number of superpixels
    while true
        if size(I,3)==1
            I = repmat(I, [1 1 3]);
        end
        
        [L] = vgg_segment_gb(I, sigma_k, k, min_sz, true);
        
        un = unique(L);
        n_segms = numel(un);
        if(the_min > n_segms)
            sigma_k = sigma_k + 0.1*rand();
            %k2 = k2 + 200*rand();
        else
            break
        end
        counter = counter + 1;
        if(counter>15)
            break;
        end
    end
    %sc(L, 'rand')
    
    % Find the size of each superpixel - order them by size
    n_p = accumarray(L(:), ones(numel(L),1));
    [val, size_order] = sort(n_p, 'descend');

    % compute the centroid for each label (superpixel)
    centroids = region_centroids_mex(uint32(L), double(max(L(:))))';
    
    % select the superpixels which are closest to [prod(n)] equally spaced 
    % grid locations (does nothing with size_order)
    id_selected = select_around_grid(I, L, centroids, n, size_order);
    id_selected = unique(id_selected);

%     % create a new label map where everything is zero except for pixels
%     % which belong to superpixels selected above. Each gets a new unique
%     % superpixel ID.
%     repl_lbl = zeros(1, length(n_p)+1);
%     repl_lbl(id_selected+1) = 1:length(id_selected);
%     L = repl_lbl(L + 1);
    
    % find the centroid of the selected superpixels
    centroids = round(centroids(id_selected,:));
    
    % sort the centroids (in linear indexing order) - this is not necessary
    % to do but makes comparisons easier between different segmenters)
%     centroids = sortrows(centroids(:,[2 1]));
%     centroids = centroids(:,[2 1]);
    
    % create the sets of pixel seeds centered around the centroids of the 
    % selected superpixels
    sets = create_seed_coords([size(I,1) size(I,2)], centroids, shape_coords);
    
    % visualize see the selected ones
    % show_selected(L, id_selected);

%             for i=1:prod(n)
%                 in_i = find(L==id_selected(i));
%                 %imshow(L==un(order(i)))
%
%                 rp = randperm(numel(in_i));
%                 rp = rp(1:size(shape_coords,1));
%                 sets{i} = in_i(rp);
%             end
end

% function [sets] = generate_seeds_prec_windows(I, windows)
%     sets = {};
% 
%     windows = clipboxes(I, windows);
%     %showboxes(I, windows);
%     for i = 1:size(windows,1)
%         if windows(i,3) > windows(i,1)
%             ids2 = floor(windows(i,1):windows(i,3))';
%         else
%             ids2 = floor(windows(i,3):windows(i,1))';
%         end
%         
%         if windows(i,4) > windows(i,2)
%             ids1 = floor(windows(i,2):windows(i,4))';
%         else
%             ids1 = floor(windows(i,4):windows(i,2))';
%         end
%         
%         sets{i} = false([size(I{1},1) size(I{1},2) length(I)]);
%         sets{i}(ids1, ids2, windows(i,5)) = true;
%         sets{i} = sets{i}(:);
%     end
% end

function sets = create_seed_coords(im_sz, centroids, shape_coords)
% generates the sets of seed pixels centered around the [centroids]. The
% [centroids] is an [n x 2] matrix, where each row gives the centroid
% pixel. The [shape_coords] is a [m x 2] matrix giving the pixel offsets
% from the centroid locations. The output [sets] is of length [n]. Each set
% in it is of size [m], giving the pixel locations for each seed point for
% a particular seed set.

    assert(~any(any(isnan(centroids))));
    
    sets = cell(size(centroids,1),1);
    
    for i=1:size(centroids,1)
        this_center = centroids(i,:);
        
        %coords = this_center + shape_coords;
        coords = round(max(1, bsxfun(@plus, this_center, shape_coords)));
        coords(:,1) = min(im_sz(1), coords(:,1));
        coords(:,2) = min(im_sz(2), coords(:,2));
        sets{i} = false([im_sz(1) im_sz(2)]);
        sets{i}(coords(:,1), coords(:,2)) = true;
        sets{i} = sets{i}(:);
    end
end

function centers = generate_centers(n_rows, n_cols, shape_coords, mn)
    shape_dims = [max(shape_coords(:,1)); ...
                  max(shape_coords(:,2))]; % assumed to be centered coords

    % incase just a scalar number provided for the approximate number of
    % total seeds required
    if isscalar(mn)
        % adjust the number of seeds on each dimension to image size
        row_to_col_ratio = n_rows / n_cols;
        total_no_seeds = prod(mn);
        mn(2) = sqrt(total_no_seeds / row_to_col_ratio);
        mn(1) = row_to_col_ratio * mn(2);
        mn = round(mn);
    end
    
    vert_start = shape_dims(1)+1;
    vert_end = n_rows-shape_dims(1)-1;
    horiz_start = shape_dims(2)+1;
    horiz_end =  n_cols-shape_dims(2)-1;

    vert_step = ((vert_end - vert_start) / (mn(1)*2));
    horiz_step = ((horiz_end - horiz_start) / (mn(2)*2));

    range_vert = vert_start:vert_step:vert_end;
    range_horiz = horiz_start:horiz_step:horiz_end;
    %assert(range_vert(end) == vert_end);
    %assert(range_horiz(end) == horiz_end);

    range_vert(3:2:end-2) = [];
    range_horiz(3:2:end-2) = [];

%             if(length(range_horiz)~=(mn(2)+2))
%                 horiz_step = round((horiz_end - horiz_start) / (mn(2) +1));
%                 range_horiz = horiz_start:horiz_step:horiz_end;
%             end

    if(length(range_vert)~=(mn(1)+2))
        vert_step = round((vert_end - vert_start) / (mn(1) +1));
        range_vert = vert_start:vert_step:vert_end;
    end

    dummy = -1;
    if(isempty(range_vert))
        range_vert = [dummy max(1,floor(n_rows/2)) dummy];
    end
    if(isempty(range_horiz))
        range_horiz = [dummy max(1, floor(n_cols/2)) dummy];
    end

    range_vert([1 end]) = [];
    range_horiz([1 end]) = [];

%             [X,Y] = meshgrid(range_vert, range_horiz);
%
%             X = reshape(X, numel(X), 1);
%             Y = reshape(Y, numel(Y), 1);
    [X,Y] = cartprod(range_vert, range_horiz);
%     assert(sqrt(length(X)) == mn(1));
%     assert(sqrt(length(Y)) == mn(2));
    centers = round([X Y]);
end

function id_selected = select_around_grid(I, L, coords, n, size_order)
% select the labels ([L] is usually a superpixel labelling) which are 
% closest to [prod(n)] equally spaced grid locations.

    % get one grid locations equally spaced by n over the image
    grid_coords = generate_centers(size(I,1), size(I,2), [0 0], n);
    
    % find the distance of each grid location from the label (superpixel)
    % centroid. Each row of D gives the distance of a grid location to all 
    % label centroids.
    D = pdist2(grid_coords, coords);
    id_selected = [];
    
    % iterate over all seed locations
    for i = 1:size(grid_coords,1)
        % select the superpixel whose centroid is closest
        [val, closest] = min(D(i,:));
        id_selected = [id_selected closest];
        D(:,closest) = inf;
    end

    %imshow(L); hold on;
    %plot(X, Y, 'x');
end

function [sets] = pixel_set_to_sp_set(pixel_sets, sp_seg, sp_seg_szs, ...
                                      min_seed_frac_sp)
	% this method will select any superpixel intersecting with pixel seeds
%     METHOD = 'ANY_INTERSECT';
    % this method will select all superpixels which have atleast a fraction
    % of their size intersecting with the pixel seeds. The min fraction for
    % size intersection given by min_seed_frac_sp.
%     METHOD = 'MIN_FRAC_SZ_INTERSECT';
    % this method sorts all the superpixels by descending fraction of their
    % size intersection with the pixel seeds, and picks the first K
    % superpixels such the total size of these K superpixels is >= to the
    % number of seed pixels
    METHOD = 'MIN_INTERSECT_PXLS';
    
    % iterate over all pixel sets, and find the superpixels these pixels
    % fall on
    sets = false([size(sp_seg_szs,1), length(pixel_sets)]);
    for set_idx = 1:length(pixel_sets)
        % find the unique superpixel ids which overlap with the seed pixels
        curr_pixel_set = pixel_sets{set_idx};
        curr_sp = sp_seg(curr_pixel_set);
        curr_sp_ind = unique(curr_sp);
        
        if strcmpi(METHOD, 'ANY_INTERSECT')
            % so that all superpixels are selected regardless
            selected_sp = true(size(curr_sp_ind));
        else
            % if method either MIN_FRAC_SZ_INTERSECT ot MIN_INTERSECT_PXLS
            curr_sp_szs = sp_seg_szs(curr_sp_ind);
            
            % find fraction of each superpixel overlapping with seed pixels
            curr_sp_inc_szs = histc(curr_sp(:), curr_sp_ind);
            curr_sp_inc_frac = curr_sp_inc_szs ./ curr_sp_szs;
            
            if strcmpi(METHOD, 'MIN_INTERSECT_PXLS')
                [curr_sp_inc_frac, sort_sp_idx] = ...
                        sort(curr_sp_inc_frac, 'descend');
                
                % select the superpixels in descending order of their
                % fraction size intersecting with pixel seeds
                curr_sp_szs = curr_sp_szs(sort_sp_idx);
                curr_sp_szs = cumsum(curr_sp_szs);
                selected_sp = curr_sp_szs < numel(curr_sp);
                selected_sp(find(selected_sp, 1, 'last') + 1) = 1;
                selected_sp(1) = 1;    % so that atleast one sp is selected
                curr_sp_ind = curr_sp_ind(sort_sp_idx);
                
            else  % MIN_FRAC_SZ_INTERSECT
                % filter based on superpixel size fraction
                selected_sp = curr_sp_inc_frac >= min_seed_frac_sp;
                if ~any(selected_sp)
                    % if all superpixels were being dropped select the one 
                    % with the the one superpixel with the largest size 
                    % fraction
                    [~, selected_sp] = max(curr_sp_inc_frac);
                end
            end
        end

        curr_sp_ind = curr_sp_ind(selected_sp);
        sets(curr_sp_ind, set_idx) = true;
    end
end

% function show_seeds(theI, seeds, on_img)
%     if(nargin==2)
%         on_img = false;
%     end
%     
%     num_pxls_im = size(theI{1},1) * size(theI{1},2);
% 
%     %imshow(obj.I);
%     for idx = 1:length(theI)
%         newI = zeros(size(theI{idx},1), size(theI{idx},2));
%         for i = 1:numel(seeds)
%             pnts_to_draw = ceil(seeds{i} / num_pxls_im) == idx;
%             newI(seeds{i}(pnts_to_draw)) = i;
%         end
%         if(on_img)
%             figure;
%             imshow(heatmap_overlay(theI{idx}, newI));
%             %sc(sc(obj.I, 'gray') + sc(newI));%sc(cat(3, obj.I, newI), 'prob');
%         else
%             sc(newI, 'rand');
%         end
%     end
% end
% 
% function show_selected(L, id_selected)
%     L2 = zeros(size(L));
%     for i=1:numel(id_selected)
%         L2(L == id_selected(i)) = i;
%     end
%     sc(L2, 'rand');
% end

function [coords] = generate_rectangle_coords(dims)
    assert(length(dims) == 2); % two numbers required
    if any(round(dims) ~= dims)
        error('expecting integer dims');
    end

    if all(dims == 1)
        coords = [0 0];
    else
        range_x = (0:dims(1)-1)';
        range_y = (0:dims(2)-1)';

        [x, y] = cartprod(range_x, range_y);

        coords = [(x - (dims(1)-1)/2)  (y - (dims(2)-1)/2)];

        if mod(dims(1), 2) == 0         % if it's even move it right / up
            coords(:,1) = coords(:,1) + 0.5;
        end

        if mod(dims(2), 2) == 0         % if it's even move it right / up
            coords(:,2) = coords(:,2) + 0.5;
        end
    end
end
