function areaBB = computeArea(bb)
%computes area of the bb=[xmin ymin xmax ymax]

if ((bb(1) > bb(3)) || (bb(2) > bb(4)))
    areaBB = 0;
else
    areaBB = (bb(3) - bb(1) + 1) * (bb(4) - bb(2) + 1);
end