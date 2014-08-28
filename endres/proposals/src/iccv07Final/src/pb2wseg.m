function wseg = pb2wseg(pb, maxsp)

nsp = Inf;
c = 1;
pb = max(pb, [], 3);
while nsp > maxsp
    if c > 1
        wseg = watershed(medfilt2(pb, [c c]));
    else
        wseg = watershed(pb);
    end
    nsp = max(wseg(:));  
    c = c + 2;
end
wseg = uint16(wseg);