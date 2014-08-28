function sp = setup_on_edge(sp, h, w)
% If an sp is on edge, sets the corresponding flag to 1. 'h' and 'w' are
% the image geight and width.

for sus = 1:length(sp)
    if sp{sus}.size == 0
        continue; % skip empty sp
    end
    
    sp{sus}.on_edge = zeros(1,4);
    
    u = sub2ind([h,w], double(sp{sus}.pixels(:,1)), double(sp{sus}.pixels(:,2))); % double() ensures there's no integer overflow
    if sum(u <= h)
        sp{sus}.on_edge(1) = 1;
    end
    if sum(u >= h*(w-1))
        sp{sus}.on_edge(2) = 1;
    end
    if sum(mod(u-1,h) == 0)
        sp{sus}.on_edge(3) = 1;
    end
    if sum(mod(u,h) == 0)
        sp{sus}.on_edge(4) = 1;
    end
end