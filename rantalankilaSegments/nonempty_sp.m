function nesp = nonempty_sp(sp)
% Returns the indices of non-empty sp

nesp = [];
for sus = 1:length(sp)
    if sp{sus}.size > 0
        nesp = [nesp, sus];
    end
end
