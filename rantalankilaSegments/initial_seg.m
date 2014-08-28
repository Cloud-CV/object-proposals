function [sp, K] = initial_seg(I, opts, I_seg)
% Given image 'I', does superpixelation using method defined by
% 'opts.seg_method'. After that, the function initializes the 'sp' and 'K'
% variables, which are used throughout the method. Outputs 'boundaries' and
% 'L' contain additional information for visualization, but are otherwise
% not required.

[h, w, ~] = size(I);

if ~isempty(I_seg) % Use user supplied segmentation
    [h2, w2, ~] = size(I_seg);
    assert(h == h2);
    assert(w == w2);
    seg_values = unique(I_seg(:)); % this should have format 1:n, but missing values are allowed
%     assert(min(seg_values) == 1);
%     assert(max(seg_values) == length(seg_values));

    ic = I_seg(:);
    
%% Use one of the three segmentation methods 'felz', 'slic', 'qshift'
elseif strcmp(opts.seg_method, 'felz')
    
    % Parameters
    sigma = opts.felz_sigma;
    k = opts.felz_k;
    min_area = opts.felz_min_area;
    
    imwrite(I,'temp.ppm','ppm'); % save as ppm
    
    % Use Felzenswalb to segment. This will only work on Windows because it
    % calls a windows executable.
    cmd = ['P:\matlab\spagglom\segment\segment ' num2str(sigma) ' ' num2str(k) ' ' num2str(min_area) ' "' 'temp.ppm' '" "temp_seg.ppm"' ];
    system(cmd);
    
    % Read produced image and delete unnecessary files
    Is = imread('temp_seg.ppm');
    delete('temp.ppm');
    delete('temp_seg.ppm');
       
    % Replace colors with unique integers
    [~, ~, ic] = unique(reshape(Is, h*w, 3), 'rows');
    Is_int = reshape(ic, h, w);
    sp_amount = max(ic);
        
elseif strcmp(opts.seg_method, 'qshift')
    % This method should work, but has not been tested extensively. Also
    % the parameters have not been tuned.
    
    % Parameters
    maxdist = 15;
    ratio = 0.5;
    kernelsize = 2.5;

    % Note that quickseg is not deterministic! results may vary between
    % runs
    Is = vl_quickseg(I, ratio, kernelsize, maxdist); % colored segmentation image, takes about 5 seconds
    [~, ~, ic] = unique(reshape(Is, h*w, 3),'rows');
    
    % code continues below
    
elseif strcmp(opts.seg_method, 'slic')
    
    Is_int = double(vl_slic(single(I), opts.slic_region_size, opts.slic_regularizer) + 1);
    [~, ~, ic] = unique(reshape(Is_int, h*w, 1));
    
    % code continues below
        
end    
    
% Further process slic, qshift and user segmentations 
if strcmp(opts.seg_method, 'slic') || strcmp(opts.seg_method, 'qshift') || ~isempty(I_seg)

    Is_int = reshape(ic, h, w);   

    sp_amount = max(Is_int(:));
        
    % Separate non-connected superpixels into individual superpixels
    sp_counter = 0;
    for k = 1:sp_amount
        CC = bwconncomp(logical(Is_int == k)); % finds connected components
        for u = 2:CC.NumObjects % if there is more than one component
            ch = CC.PixelIdxList{u};
            sp_counter = sp_counter + 1;
            Is_int(ch) = sp_amount + sp_counter; % give a new superpixel label
        end
    end
    I_lin = Is_int(:);
    
    % remove unused indices
    [~, ~, ic] = unique(I_lin);
    Is_int = reshape(ic, h, w);
    sp_amount = max(Is_int(:)); 
   
end % slic or qshift



%% Find superpixels, neighbors and boundaries 

% Create superpixels (initialize 'sp')
sp = cell(sp_amount, 1);
for i = 1:sp_amount
    [row, col] = find(Is_int == i);
    sp{i}.pixels = uint16([row, col]); % uint16 calls save space but may cause unexpected errors with sub2ind() and the like
    sp{i}.size = double(length(row))/(h*w); % fractional size of sp 
end

L = zeros(sp_amount, sp_amount, 'uint16'); % Stores id's of neighboring superpixel pairs
K = []; % will store indices of adjacent superpixels
bnum = 0; % an id counter

% Find neighboring superpixels
% horizontal borders
for i = 1:h
    for j = find(Is_int(i,1:end-1) - Is_int(i,2:end)) % values of j at which Is_int changes, that is, there is a boundary  
        r = sort([Is_int(i,j), Is_int(i,j+1)]); % Use L as an upper triangular matrix for storing pair information
        
        if L(r(1),r(2)) == 0 % previously unseen neighbors
            bnum = bnum + 1; % create new id number
            L(r(1),r(2)) = bnum; % create link id
            K = [K; r(1), r(2)]; % store the pair
        end % if L(r1,r2) == 0       
    end % for j
end % for i

% vertical borders
for j = 1:w
    for i = find((Is_int(1:end-1,j) - Is_int(2:end,j))')
        r = sort([Is_int(i,j), Is_int(i+1,j)]);
        
        if L(r(1),r(2)) == 0
            bnum = bnum + 1;
            L(r(1),r(2)) = bnum;
            K = [K; r(1), r(2)];   
        end % if L(r1,r2) == 0       
    end % for j
end % for i

%%

if opts.diagonal_connections % Use 8-connectivity instead of default 4-connectivity
    
    % nw-se diagonal borders
    for i = 1:h-1
        for j = 1:w-1
            if Is_int(i,j) ~= Is_int(i+1,j+1)
                r = sort([Is_int(i,j), Is_int(i+1,j+1)]);
                if L(r(1),r(2)) > 0
                    
                elseif L(r(1),r(2)) == 0
                    bnum = bnum + 1;
                    L(r(1),r(2)) = bnum;
                    K = [K; r(1), r(2)];
                end % if L(r1,r2) == 0
            end % if
        end % for j
    end % for i
    
    % ne-sw diagonal borders
    for i = 2:h
        for j = 1:w-1
            if Is_int(i,j) ~= Is_int(i-1,j+1)
                r = sort([Is_int(i,j), Is_int(i-1,j+1)]);
                if L(r(1),r(2)) > 0 %
                    
                elseif L(r(1),r(2)) == 0
                    bnum = bnum + 1;
                    L(r(1),r(2)) = bnum;
                    K = [K; r(1), r(2)];
                end % if L(r1,r2) == 0
            end % if
        end % for j
    end % for i
    
end % if opts.diagonal_connections 

% Save the neighborhood information in L to individual superpixels
M = L + L';
for i = 1:sp_amount
    sp{i}.neighbors = find(M(i,:)); % indices of neighbors
    sp{i}.parts = [i]; % At the start, each superpixel is made of single part of the original superpixelation. When the superpixels later merge, this variable will union the parts, which can then be used to reconstruct the corresponding pixel set
    sp{i}.on_edge = zeros(1,4);
end




