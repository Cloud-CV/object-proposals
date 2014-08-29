function [sp, K, scores, region_parts] = spagglom_sub(sp, K, scores, initial_sp_created, opts)
% Performs "local search" by agglomerating superpixels. Returns the created
% regions and the current superpixelation status. Has two primary modes
% called phases. Phase 1 stops agglomeration when a certain similarity
% score threshold has been reached, while phase 2 continues as long as
% there is more than one superpixel left.
% This function should be called from spagglom.m, after the inputs have
% been initialized.

region_parts = []; % return value containing segmentation proposals
cur_max_score = inf;

pp = 0; % debugging counter

%% Add each superpixel of current superpixelation as a region
if ~initial_sp_created
    initial_sp_created = 1;
    for i = 1:length(sp)
        if size(sp{i}.pixels,1) > 0
            region_parts{end+1} = sp{i}.parts;
        end
    end
end

%% If we are in phase 2 and not interested in merged regions, there's no need to run the algorithm any further...
if ~opts.collect_merged_regions && opts.phase == 2
    if ~initial_sp_created
       warning('spagglom_sub returns nothing.'); % ...but generally we would only want to stop here if we did above initial_sp_created routine.
    end
    return 
end


%% Run the agglomeration loop
% Run phase 1 until 'opts.start_phase2' threshold is reached
% Run phase 2 until one superpixel left
while (opts.phase == 1 && cur_max_score > opts.start_phase2) || (opts.phase == 2 && size(K,1) > 0)
        
    pp = pp + 1;
      
    %% Find the superpixel pair with highest score
    cur_max_score = max(scores);  
    kmax = find(scores == cur_max_score);
         
    % Label the pair as grow and die
    g = sort(K(kmax(1),1:2));
    grow = g(1); % grow < die
    die  = g(2);
        
    %% Merge the two superpixels        
    sp{grow}.pixels = [sp{grow}.pixels; sp{die}.pixels]; % append pixels   
    sp{grow}.hist = merge_histograms(sp, [grow,die]); % update histograms
    
    sp{grow}.parts = [sp{grow}.parts, sp{die}.parts];
    sp{die}.parts = [];

    sp{grow}.size = sp{grow}.size + sp{die}.size; % sum fractional sizes
    sp{die}.pixels = [];
    sp{die}.hist = []; % different from histogram of zeros
    sp{die}.size = 0;
       
    sp{grow}.on_edge = sign(sp{grow}.on_edge + sp{die}.on_edge);   
         
    if opts.collect_merged_regions % by default 1
        region_parts{end+1} = sp{grow}.parts;
    end
        
    % Adjust neighbors-variable of (new) grow and die
    temp = unique([sp{grow}.neighbors, sp{die}.neighbors]); % pool neighbors and remove duplicates
    sp{grow}.neighbors = temp(temp ~= grow & temp ~= die); % remove die and grow from neighbors
    sp{die}.neighbors = [];
    
    % Adjust neighbors-variable of neighbors of new grow
    for t = sp{grow}.neighbors
        temp = sp{t}.neighbors;
        sp{t}.neighbors = [grow, temp(temp ~= grow & temp ~= die)]; % add grow (and remove extra) and remove die (if present)
    end
    
    % Remove all lines of K that contain grow or die in either column
    y = find(K(:,1) == grow | K(:,1) == die | K(:,2) == grow | K(:,2) == die);
    K(y,:) = [];
    scores(y) = []; % remove corresponding scores
    
    % Form new pairs by linking grow to all its neighbors
    K_new = [grow*ones(length(sp{grow}.neighbors),1), sp{grow}.neighbors'];
    
    % Compute scores for those new pairs and update pairs and scores
    scores = [scores, similarity_scores(sp, K_new, opts)];
    K = [K; K_new];  
    
end 


