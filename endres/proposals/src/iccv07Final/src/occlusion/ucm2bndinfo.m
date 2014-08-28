function bndinfo = ucm2bndinfo(ucm)
% bndinfo = ucm2bndinfo(ucm)

minsize = 0;
seg = bwlabel(ucm<1); 

%% fill in boundary pixels
ind = find(seg(1, 2:end)==0 & seg(1, 1:end-1)==0); % boundaries in top row that are adjacent to other boundaries
seg(1, ind) = seg(2, ind);
seg(1, ind+1) = seg(2, ind+1);
ind = find(seg(2:end, 1)==0 & seg(1:end-1, 1)==0); % boundaries in left col that are adjacent to other boundaries
seg(ind, 1) = seg(ind, 2);
seg(ind+1,1) = seg(ind+1,2);
ind = seg(2:end, :)==0; % boundaries below top row
seg([false(1, size(ind, 2)) ; ind]) = seg([ind ; false(1, size(ind, 2))]); 
if seg(1,1)==0, seg(1,1)=seg(1,2); end;
ind = find(seg==0); % any remaining boundary pixels
seg(ind) = seg(ind-size(seg, 1));

%% create bndinfo structure
[edges, juncts, neighbors, wseg] = seg2fragments(double(seg), [], minsize);
bndinfo = processBoundaryInfo(wseg, edges, neighbors);

% store boundary strength
ind = getBoundaryCenterIndices(bndinfo);
pB = ucm(ind-1-size(ucm,1));
bndinfo.pbnd = pB;
