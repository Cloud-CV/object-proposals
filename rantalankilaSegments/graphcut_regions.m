function graphcut_parts = graphcut_regions(sp, K, opts)
% Performs "global search" on superpixel graph defined by 'sp' and 'K'

graphcut_parts = [];
graphcut_params = zeros(0,3);

seg_amount = 0;
seg_size = 0;

branch_counter = 0;

sp_amount = length(sp);
sp_sizes = zeros(1,sp_amount);
for ui = 1:sp_amount
    sp_sizes(ui) = sp{ui}.size;
end

nesp = nonempty_sp(sp); % if sp indexing was redone, this returns 1:length(sp)
nesp_comp = setdiff_fast(1:sp_amount, nesp); 

%% Pairwise scores
pairwise_weights = [1,1,0]; % Remove the size feature. Give multiple rows for multiple weight combinations

scores = zeros(size(pairwise_weights,1), size(K,1));
for s = 1:size(pairwise_weights,1)
    opts.feature_weights = pairwise_weights(s,:);
    scores(s,:) = similarity_scores(sp, K, opts);
end

%% Unary scores weights
opts.feature_weights = [1,1,0]; % By default, same as the pairwise_weights

%% Calculate foreground scores for each foreseed
fore_scores_all = zeros(length(nesp), length(nesp));
for foreseed = nesp % each single superpixel in turn
    foreseed_neighbors{foreseed} = [foreseed, sp{foreseed}.neighbors]; % add immediate neighbors
    forecomp{foreseed} = setdiff_fast(nesp, foreseed); % comp = complement
    fore_scores_all(foreseed, forecomp{foreseed}) = scores_against_sp_group(sp, foreseed_neighbors{foreseed}, forecomp{foreseed}, opts); % get scores of the foreseed group against all other sp
end
    
%% Select backseeds
edge_stats = zeros(sp_amount,4);
for sus = nesp
   edge_stats(sus,:) = sp{sus}.on_edge;  
end

% Use combinations of superpixels on the edges
backseed_all{1} = find(sum(edge_stats(:,[3,4]), 2))'; % top and bottom edges
backseed_all{2} = find(sum(edge_stats(:,[1,2]), 2))'; % left and right edges
backseed_all{3} = find(sum(edge_stats(:,:), 2))'; % all edges
backseed_all{4} = find(sum(edge_stats(:,[1,3]), 2))'; % all other pairs
backseed_all{5} = find(sum(edge_stats(:,[1,4]), 2))';
backseed_all{6} = find(sum(edge_stats(:,[2,3]), 2))';
backseed_all{7} = find(sum(edge_stats(:,[2,4]), 2))';
backseed_all{8} = find(sum(edge_stats(:,[2,3,4]), 2))'; % all except left
backseed_all{9} = find(sum(edge_stats(:,[1,3,4]), 2))'; % all except right
backseed_all{10}= find(sum(edge_stats(:,[1,2,3]), 2))'; % all except bottom
backseed_all{11}= []; % nothing

% 10, 2, 6, 4 are best
% 3 is quite good
% 1, 8, 9, 11 average
% 5, 7 are worst

% Get scores against each of the backseeds
for backseed_type = 1:length(backseed_all)
    backcomp{backseed_type} = setdiff_fast(nesp, backseed_all{backseed_type}); % complement
    if ~isempty(backseed_all{backseed_type}) % ordinary case
        back_scores_ind{backseed_type} = backcomp{backseed_type};
        back_scores{backseed_type} = scores_against_sp_group(sp, backseed_all{backseed_type}, backcomp{backseed_type}, opts);
    else % if the backseed is empty (case 11), use every superpixel in the image for the histograms
        back_scores_ind{backseed_type} = nesp;
        back_scores{backseed_type} = scores_against_sp_group(sp, nesp, backcomp{backseed_type}, opts); % bg histogram using all sp (the whole image), calculated against every single sp. The function is slow so it's better to run as few times as possible.
    end
end

%% Load graph cut parameter ordering   
loadname = sprintf('complementary_branch_list_thresh%d_count%d', 5, 1); % thresh 5, count 1 seems best and simplest
load('graphcut_params_data'); % sets 'graphcut_params', list of all parameters
load(loadname); % sets 'complementary_branch_list', list of indexes for above
sgp = graphcut_params(complementary_branch_list,:);

%% Run n first branches (parameter sets) (default 15)
for branch_num = 1:opts.gc_branches

backseed_type = sgp(branch_num,1); % load the three parameters from the current set
lambda        = sgp(branch_num,2);
alpha         = sgp(branch_num,3);

% These three loops give the values in 'graphcut_params_data'
% for backseed_type = [1:4,6,8:11] % 5 and 7 are not good
% for lambda = 0.75:0.25:3
% for alpha = [1./(1:7), 2:6]

branch_counter = branch_counter + 1;
%graphcut_params(branch_counter,:) = [backseed_type, lambda, alpha];

%% Loop every backcomp sp as foreground seed
for foreseed = backcomp{backseed_type}

%% Data cost (Unary term)
Dc = zeros(2, sp_amount); % Column 1 is the set of foreground penalties (energies), and 2 is for background. One row per superpixel

if ~isempty(back_scores_ind{backseed_type})
    Dc(1,back_scores_ind{backseed_type}) = back_scores{backseed_type}; % Penalty for for assigning similiar to backseed sp to foreground
end
Dc(2,forecomp{foreseed}) = lambda*fore_scores_all(foreseed, forecomp{foreseed}); % Penalty for for assigning similiar to foreseed sp to background
Dc(1,backseed_all{backseed_type}) = 100; % "Infinite" penalty for assigning backseed sp to foreground
Dc(2,foreseed) = 100; % "Infinite" penalty for assigning foreseed sp to background

Dc(2,foreseed_neighbors{foreseed}) = 5*Dc(2,foreseed_neighbors{foreseed}); % increase penalty for labeling foreseed neighbors as background in order to reduce trivial graph cuts

%for s = 1:size(pairwise_weights,1)
s = 1;

%% Smoothness term, spatial part
paircosts = alpha*scores(s,:);

%% Perform the graphcut
% These methods all give the same results (last one only approximately)
if 1
    % RECOMMENDED
    % GCMex - MATLAB wrapper for graph cuts multi-label energy minimization
    % http://vision.ucla.edu/~brian/gcmex.html
    Ss = sparse(K(:,1), K(:,2), paircosts, sp_amount, sp_amount);
    Ss = Ss + Ss';
    [labels, ~, ~] = GCMex(zeros(sp_amount,1), single(Dc), Ss, single([0, 1; 1, 0]), 0);
elseif 1
    [labels, ~] = SolveQPBO(Dc, K', [0; 1; 1; 0]*paircosts);   
elseif 0
    % On my machine, this implementation uses lots of memory, which
    % sometimes leads to a crash.
    Ss = sparse(K(:,1), K(:,2), paircosts, sp_amount, sp_amount);
    Ss = Ss + Ss';
    gch = GraphCut('open', Dc, [0, 1; 1, 0], Ss);
    %[gch labels] = GraphCut('expand',gch);
    [gch labels] = GraphCut('swap',gch);
    gch = GraphCut('close', gch);
    labels = labels';
elseif 0
    % GCoptimization - software for energy minimization with graph cuts
    % Version 3.0
    % http://vision.csd.uwo.ca/code/
    % This version only accepts int32 valued weights, and gives an error
    % for too large values. So it is not as accurate as the other methods.
    round_int32 = 10^4;
    Ss = sparse(K(:,1), K(:,2), paircosts, sp_amount, sp_amount);
    Ss = Ss + Ss';
    gch = GCO_Create(sp_amount, 2); % only call once?
    GCO_SetDataCost(gch, int32(round_int32*Dc));
    GCO_SetSmoothCost(gch, [0, 1; 1, 0]);
    GCO_SetNeighbors(gch, round(round_int32*Ss));
    GCO_Expansion(gch); % Compute optimal labeling via alpha-expansion
    labels = GCO_GetLabeling(gch) - 1;
    GCO_Delete(gch); % only call once?
else
    error('Please select one graph cut implementation.');
end


%% Save the solved segmentation
labels(nesp_comp) = 1; % Important(?). Sets sp of size zero to background, because they may not have size zero in the sp variable used outside this function
seg = find(1 - labels);

seg_amount = seg_amount + 1;
seg_size = seg_size + length(seg);

if opts.sp_reindexed
    %if length(seg) > 1 && length(seg) ~= length(backcomp) % ignore trivial graphcuts
    if 1 % Graphcuts of length 1 are very useful if they are not collected in the greedy branch!
        graphcut_parts{end+1} = seg; % save the region. This is faster than below method, but only works if sp updating was run before graphcut, so that each sp has only one part.
        %graphcut_branch(end+1) = branch_counter;
    end
else
    seg_parts = [];
    %if length(seg) > 1 && length(seg) ~= length(backcomp)
    if 1
        for i = seg
            seg_parts = [seg_parts, sp{i}.parts];
        end
        graphcut_parts{end+1} = seg_parts;
        %graphcut_branch(end+1) = branch_counter;
    end
end


end % foreseed loop

%%% parameter loops start
% end
% end
% end
% %%% parameter loops end
end % for branch_num


