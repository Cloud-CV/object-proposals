function comb = floodfill_sp(sp, seed)
% Gets the connected component (in sense of sp neighborhood variable) which
% the index 'seed' is part of.
% If 'sp' represents a whole image, then there is a connection from each
% superpixel to another, and the floodfill will fill the whole image, returning
% the set of all superpixels. But in floodfill_sp_all.m, the 'sp' variable is
% modified by removing superpixels, so the floodfill may be non-trivial.

to_fill = seed;
comb = seed;

while ~isempty(to_fill)
    to_fill_next = [];
    for u = to_fill
        to_fill_next = [to_fill_next, sp{u}.neighbors]; % add all neighbors
    end
    
    to_fill = setdiff_fast(to_fill_next, comb); % remove already filled sp
    comb = [comb, unique(to_fill)]; % it's probably not very efficient calling unique() this often        
end

% nothing left to fill, return all filled sp