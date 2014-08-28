function [sp, K, scores] = update_sp_indexing(sp, K, h, w, opts)
% After spagglom_sub.m has been run for a while (phase1, obtaining the
% refined superpixelation), The 'sp' variable contains lots of useless
% empty superpixels and the superpixels are made of multiple parts. If this
% information is not required (by default it's not), this function can be
% run to simplify the 'sp' variable and accordingly update neighbor
% variable 'K'.

cc = 1; % a counter
sp_old = sp;
sp = [];
key = [];

% Build each superpixel
for q = 1:length(sp_old)
    if size(sp_old{q}.pixels,1) > 0 % remove empty sp by ignoring them
        sp{cc} = sp_old{q}; % copy the old information
        sp{cc}.parts = [cc]; % each sp has one part, which is the same as its index
        key(end+1,1:2) = [q, cc]; % contruct mapping from old to new indexing
        cc = cc + 1;
    end
end

sp_amount = length(sp);

% Spply mapping to update sp labels
K = arrayfun(@(x)key(key(:,1) == x, 2), K); % changes each value of K by lookup using table matrix 'key'
for q = 1:length(sp)
    sp{q}.neighbors = arrayfun(@(x)key(key(:,1) == x, 2), sp{q}.neighbors); % same for neighbors
end

% List pixel coordinates in index format
for sus = 1:sp_amount  
    sp{sus}.spind = sub2ind([h,w], double(sp{sus}.pixels(:,1)), double(sp{sus}.pixels(:,2)));
end

% Recalculate scores
scores = similarity_scores(sp, K, opts); % rows of this variable have been permutated. Instead of solving the permutation, we just recalculate the values.

