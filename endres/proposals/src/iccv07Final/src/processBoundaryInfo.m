function bndinfo = processBoundaryInfo3(seg, edges, neighbors)
%
% bndinfo = processBoundaryInfo3(bndinfo)
%
% Adds several fields to the bndinfo structure based on bndinfo.wseg
% 
% Input:
%   bndinfo.wseg(imh,imw) = oversegmentation with edges set to 0; uint16
%
% Output:
%   bndinfo.    
%     wseg(imh, imw) = oversegmentation (uint16)
%     nseg  = number of segments
%     ne = number of edglets
%     nj = number of junctions
%     edges.
%       indices{ne} = cell array of pixel indices for each edglet
%       adjacency{2*ne} = directed adjacency for each edge
%                         1..ne s.t. j1-->j2;   ne+1..2*ne s.t. j2-->j1
%       junctions(ne, 2) = junction indices for each edgelet ([j1 j2]) (uint32)                 
%       spLR(ne, 2) = superpixel indices to [left right] of edglet (uint16)
%       thetaDirected(ne, 1) = orientation from j1 --> j2 (-pi to pi)
%       thetaUndireted(ne, 1) = undirected orientation (-pi/2 to pi/2)
%     junctions.
%       position(nj, 2) = mean [x y] position for each junction
%
% Notes:
%   1) Edglet indices 1..ne traverse from j1 --> j2.  Edglet indices 
%   ne+1 --> 2*ne traverse from j2 --> j1.  Some statistics for latter
%   (e.g. thetaDirected) are not stored, as they can be easily calculated
%   from forward direction.  
%

%% Get basic stats

e2j = neighbors.fragment_junctionlist;
j2e = neighbors.junction_fragmentlist;
spLR = cat(1, neighbors.fragment_segments{:});

ne = numel(edges);
nj = numel(j2e);
nseg = max(seg(:));

[imh, imw] = size(seg);


%% Ensure that all edglets have two junctions and get junction positions
%j2e = [j2e(:) ; cell(nj, 1)];
jpos = zeros(nj*2, 2);
for k = 1:ne
    if numel(e2j{k}) < 2
        nj = nj + 1;
        e2j{k}(2) = nj;
        %j2e{nj} = k;
    end
    jpos(e2j{k}(1), :) = edges{k}(1, :);
    jpos(e2j{k}(2), :) = edges{k}(end, :);
end
jpos(nj+1:end, :) = [];
%j2e(nj+1:end) = [];


%% Check for an edglet having the same superpixel on both sides

ind = find(spLR(:, 1)==spLR(:,2));
for k = ind(:)'
    mi = ceil(size(edges{k},1)/2);
    ni = mi + 1;
    mid = [edges{k}(mi, 1) edges{k}(mi, 2)];
    next = [edges{k}(ni, 1) edges{k}(ni, 2)];
    if next(1) == mid(1)+1 % going right
        spl = seg(mid(2)-0.5, mid(1)+0.5);
        spr =  seg(mid(2)+0.5, mid(1)+0.5);
    elseif next(1) == mid(1)-1 % going left
        spl = seg(mid(2)+0.5, mid(1)-0.5);
        spr =  seg(mid(2)-0.5, mid(1)-0.5);
    elseif next(2) == mid(2)-1 % going up
        spl = seg(mid(2)-0.5, mid(1)-0.5);
        spr =  seg(mid(2)-0.5, mid(1)+0.5);  
    elseif next(2) == mid(2)+1 % going down
        spl = seg(mid(2)+0.5, mid(1)+0.5);
        spr =  seg(mid(2)+0.5, mid(1)-0.5);         
    end
    
    spLR(k, :) = [spl spr];
    
end
    
%% Get directed edgelet/junction adjacency

ejunctions = cat(1, e2j{:});

% find non-unique edges (unique edge has unique pair of junctions)
jnums = max(ejunctions, [], 2) + nj*(min(ejunctions, [], 2)-1);
[uniquej, uniqueind] = unique(jnums);
notunique = setdiff((1:ne), uniqueind);
issame = zeros(ne, 1);
minj = min(ejunctions, [], 2); maxj = max(ejunctions, [], 2);
mins = min(spLR, [], 2); maxs = max(spLR, [], 2);
for k = notunique
    issame(k) = sum(minj(k)==minj & maxj(k)==maxj & ...
        mins(k)==mins & maxs(k)==maxs)>1;       
end
uniqueind = find(~issame);

% remove non-unique edges
edges = edges(uniqueind);
ne = numel(edges);
ejunctions = ejunctions(uniqueind, :);
spLR = spLR(uniqueind, :);

% get 1) junctions adjacent to each edglet
%     2) junction adjacency in form of [directedEdglet nextJunction]
jadj = cell(nj, 1);
for k = 1:ne   
    jadj{ejunctions(k, 1)}(end+1, 1) = k;  % forward
    jadj{ejunctions(k, 2)}(end+1, 1) = k;  % reverse    
%    jadj{ejunctions(k, 1)}(end+1, :) = [k ejunctions(k, 2)]; % forward
%    jadj{ejunctions(k, 2)}(end+1, :) = [k ejunctions(k, 1)]; % reverse
end

% get directed edglet adjacency
eadj = cell(ne*2, 1);
for k = 1:ne
    % forward edge: assign adjecent edges (+ne if adj edge is reverse)
    j = ejunctions(k, 2);    
    eadj{k} = jadj{j}(:);  % remove current edge
    eadj{k}(eadj{k}==k) = [];
    %eadj{k} = setdiff(jadj{j}(:, 1), k); 
    reverseind = (ejunctions(eadj{k}, 2)==j); % reverse if meet at 2nd junction
    eadj{k}(reverseind) = ne+eadj{k}(reverseind);
    % backward edge: assign adjecent edges (+ne if adj edge is reverse)
    j = ejunctions(k, 1);    
    eadj{k+ne} = jadj{j}(:);  % remove current edge
    eadj{k+ne}(eadj{k+ne}==k) = [];    
    %eadj{k+ne} = setdiff(jadj{j}(:, 1), k); 
    reverseind = (ejunctions(eadj{k+ne}, 2)==j); % reverse if meet at 2nd junction first
    eadj{k+ne}(reverseind) = ne+eadj{k+ne}(reverseind);
end



%% Get edglet orientation from j1 to j2 (pi/2 rad is pointed up)

etheta2 = zeros(ne, 1); % directed orientation
etheta = zeros(ne, 1); % undirected orientation
for k = 1:ne    
        
    jx = jpos(ejunctions(k, :), 1); 
    jy = jpos(ejunctions(k, :), 2); 
    etheta2(k) = atan2(-(jy(2)-jy(1)), jx(2)-jx(1));
    etheta(k) = mod(etheta2(k) + pi/2, pi)-pi/2;
    if etheta(k)==-pi/2, etheta(k) = pi/2; end    

end


%% Change edges from positions to indices
for k = 1:numel(edges)
    edges{k} = [min(ceil(edges{k}(:, 1)), imw) min(ceil(edges{k}(:, 2)), imh)];
    edges{k} = uint32(edges{k}(:, 2) + imh*(edges{k}(:, 1)-1));
end
                  

%% Store data in bndinfo

bndinfo.wseg = uint16(seg);
bndinfo.imsize = [imh imw];

bndinfo.ne = ne;
bndinfo.nj = nj;
bndinfo.nseg = nseg;

bndinfo.edges.indices = edges;
bndinfo.edges.adjacency = eadj;
bndinfo.edges.junctions = uint32(ejunctions);
bndinfo.edges.spLR = uint16(spLR); % superpixels on left/right side for j1 --> j2
bndinfo.edges.thetaDirected = etheta2;
bndinfo.edges.thetaUndirected = etheta;

bndinfo.junctions.position = jpos;





