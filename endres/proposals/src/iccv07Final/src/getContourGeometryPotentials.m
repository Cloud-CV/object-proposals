function [factors, vars] = getContourGeometryPotentials3(pB, pC, edgeind, pg, bndinfo, penalty)
%
% [factors, vars] = getContourPotentials(pB, pC, edgeind, bndinfo, penalty)
%
% Note: the description below is mostly inaccurate. penalty gives the
% factor term for inconsistent junctions (1E-4 by default).
%
% Solves for y given boundary and continuity likelihoods and an adjacency
% list for each edge.  The MRF is constructed as a directed graph (that is,
% Eij(0,1)~=Eij(1,0)).  Each edgelet in the image forms two nodes in the
% graph (one for occlusions in each direction).  A link between these two
% nodes disallows them to both be 1.  Links between adjacent nodes in the
% directed graph encode the conditional term P(ej | ei).  Auxialliary
% junction nodes disallow edglets to begin from nowhere or end nowhere.
%
% Inputs:
%  pB(nedglets, 2): unary likelihoods
%  pC(npairs): p(ei = 1 | ej=1)
%  edgind(npairs, 2): edgelet indices
%  eadj{nedglets}: edge adjacency 
%

% Initial:
%   E*_i = [ -log[P(ei=0 | x)]       0 ]
%   E*_ji = [ 0                         0       
%            -log[P(ei=0|ej=1, x)]      -log[P(ei=1|ej=1, x)] ]
%
% Convert to below if not on a border junction:
%   K_i = min_j(E*_ji(2,2))
%   E_i = [E*_i(0)      K_i] 
%   E_ji = [0                       0       
%           E*_ji(2,1)-E*_i(0)      E*_ji(2,2)-K_i ]
%
% Junctions:
%   Infinite penalty for contour end and start, except at border junctions
%   Small penalty for T-junctions



%% Initialize edge data


if ~exist('penalty', 'var') || isempty(penalty)
    penalty = 1E-4;
end

VIOLATION_PROB = penalty;  % probability value for impossible junction
rescale = 0;

ne = bndinfo.ne;

if rescale
    maxPon = pB(:, 2);
    for k = 1:size(edgeind, 1)
        maxPon(edgeind(k, 2)) = max(maxPon(edgeind(k, 2)), pC(k));
    end
    for k = 1:size(edgeind, 1)
        pC(k) = pC(k) ./ maxPon(edgeind(k, 2));    
    end
end

% continuity likelihood matrix
pCm = spalloc(ne*2, ne*2, size(edgeind, 1));
pCm(edgeind(:,2) + ne*2*(edgeind(:, 1)-1)) = pC; % P(e_out=1 | e_in=1, x)

% relative angles
ra = spalloc(ne*2, ne*2, size(edgeind, 2));
theta = bndinfo.edges.thetaDirected*180/pi;
theta = [theta ; theta + 180];
theta = mod(theta, 360);
eadj = bndinfo.edges.adjacency;
for k = 1:numel(eadj)  
    for k2 = eadj{k}
        ra(k, k2) = mod(theta(k2) - mod(theta(k)-180, 360) , 360);
%        ra(k, k2) = mod(theta(k2)-theta(k), 360);
    end
end

%% Initialize junction data


%ind = (ejunctions(:, 1)==ejunctions(:, 2)); % a loop
%ejunctions(ind, :) = [];

nj = bndinfo.nj;
jund = repmat({[0 0 0 0]}, nj, 1);
jin = repmat({[0 0 0 0]}, nj, 1);
jout = repmat({[0 0 0 0]}, nj, 1);
jsize = zeros(nj, 1);
ejunctions = bndinfo.edges.junctions;
for k = 1:size(ejunctions, 1)
    j1 = ejunctions(k, 1);
    j2 = ejunctions(k, 2);
    
    if j1~=j2
    
        jsize(j1) = jsize(j1)+1;
        jsize(j2) = jsize(j2)+1;

        jout{j1}(jsize(j1)) = k;  % e_k: j1 --> j2
        jin{j2}(jsize(j2)) = k;
        jout{j2}(jsize(j2)) = k+ne; % e_(k+ne): j2-->j1
        jin{j1}(jsize(j1)) = k+ne;
        jund{j1}(jsize(j1)) = k;
        jund{j2}(jsize(j2)) = k;
        
    else
        
        jsize(j1) = 1;
        jout{j1}(1) = k;
        jund{j1}(1) = k;
        jin{j1}(1) = k+ne;
    end
end
for k = 1:nj
    [jund{k}, jind] = sort(jund{k}(1:jsize(k)));
    jin{k} = jin{k}(1:jsize(k));
    jout{k} = jout{k}(1:jsize(k));
    jin{k} = jin{k}(jind);
    jout{k} = jout{k}(jind);
end


%% Initialize factor graph
nfactors = ne + nj;
factors = cell(nfactors, 1);
vars = cell(nfactors, 1);


%% Unary factors
for k = 1:ne
    
    if rescale
        jpot = [pB(k, 1) ;  maxPon(k) ; maxPon(ne+k)];
    else
        jpot = [pB(k, 1) ;  1 ; 1]; %sqrt(pB(k,2))  ; sqrt(pB(ne+k, 2))];
    end    
    
    factors{k} = jpot;
    vars{k} = k;
end 


%% Junction factors
for k = 1:nj
    
    fk = k + ne;    
    
    switch jsize(k)

        case 0 % indicates a loop
            jpot = [];
            
        case 1            
            out1 = 2+(jout{k}(1)>ne); in1 = (4-out1)+1;  % out and in = 2 or 3
            jpot = ones(3,1);                       
            
            jpot(1) = 1;
            jpot(out1) = pB(jout{k}, 2);
            
            if mod(jout{k}(1)-1,ne)~=mod(jin{k}(1)-1,ne) % not a loops
                jpot(in1) = 1;                                   
            else
                jpot(in1) = pB(jin{k}, 2);
            end
            
        case 2      
            out1 = 2+(jout{k}(1)>ne); in1 = (4-out1)+1;  % out and in = 2 or 3
            out2 = 2+(jout{k}(2)>ne); in2 = (4-out2)+1;
            jpot = ones(3,3);            
            
            jpot(1, 1) = 1;  
            jpot(out1, in2) = pCm(jout{k}(1), jin{k}(2));
            jpot(in1, out2) = pCm(jout{k}(2), jin{k}(1));
        
        case 3
            ji1 = jin{k}(1);  ji2 = jin{k}(2);  ji3 = jin{k}(3);
            jo1 = jout{k}(1);  jo2 = jout{k}(2);  jo3 = jout{k}(3);
            out1 = 2+(jo1>ne); in1 = (4-out1)+1;  
            out2 = 2+(jo2>ne); in2 = (4-out2)+1;
            out3 = 2+(jo3>ne); in3 = (4-out3)+1;  
            jpot = VIOLATION_PROB*ones(3,3,3);          
            
            % zero in, zero out
            jpot(1,1,1) = 1;
            
            % one in, one out
            jpot(out1, in2, 1) = pCm(jo1, ji2);
            jpot(out1, 1, in3) = pCm(jo1, ji3);
            jpot(in1, out2, 1) = pCm(jo2, ji1);
            jpot(1, out2, in3) = pCm(jo2, ji3);
            jpot(in1, 1, out3) = pCm(jo3, ji1);
            jpot(1, in2, out3) = pCm(jo3, ji2);                                       
            
            % two in, one out: ra = rel angle (larger means more leftward) 
            jpot(out1, in2, in3) = ...
                (ra(ji2, jo1)>ra(ji3, jo1))*pCm(jo1, ji2) + ...
                (ra(ji2, jo1)<=ra(ji3, jo1))*pCm(jo1, ji3);
            jpot(in1, out2, in3) = ...
                (ra(ji1, jo2)>ra(ji3, jo2))*pCm(jo2, ji1) + ...
                (ra(ji1, jo2)<=ra(ji3, jo2))*pCm(jo2, ji3);            
            jpot(in1, in2, out3) = ...
                (ra(ji1, jo3)>ra(ji2, jo3))*pCm(jo3, ji1) + ...
                (ra(ji1, jo3)<=ra(ji2, jo3))*pCm(jo3, ji2);            
            
            % one in, two out 
            jpot(out1, out2, in3) = ...
                (ra(ji3, jo1)>ra(ji3, jo2))*pCm(jo1, ji3)*pB(jo2, 2) + ...
                (ra(ji3, jo1)<=ra(ji3, jo2))*pCm(jo2, ji3)*pB(jo1, 2);
            jpot(out1, in2, out3) = ...
                (ra(ji2, jo1)>ra(ji2, jo3))*pCm(jo1, ji2)*pB(jo3, 2) + ...
                (ra(ji2, jo1)<=ra(ji2, jo3))*pCm(jo3, ji2)*pB(jo1, 2);            
            jpot(in1, out2, out3) = ...
                (ra(ji1, jo2)>ra(ji1, jo3))*pCm(jo2, ji1)*pB(jo3, 2) + ...
                (ra(ji1, jo2)<=ra(ji1, jo3))*pCm(jo3, ji1)*pB(jo2, 2);   
            
        case 4
            ji1 = jin{k}(1);  ji2 = jin{k}(2);  ji3 = jin{k}(3);  ji4 = jin{k}(4);
            jo1 = jout{k}(1);  jo2 = jout{k}(2);  jo3 = jout{k}(3);  jo4 = jout{k}(4);
            out1 = 2+(jo1>ne); in1 = (4-out1)+1;  
            out2 = 2+(jo2>ne); in2 = (4-out2)+1;
            out3 = 2+(jo3>ne); in3 = (4-out3)+1;  
            out4 = 2+(jo4>ne); in4 = (4-out4)+1; 
            jpot =  VIOLATION_PROB*ones(3,3,3,3);            
            
            % zero in, zero out
            jpot(1,1,1,1) = 1;
            
            % one in, one out
            jpot(out1, in2, 1, 1) = pCm(jo1, ji2);           
            jpot(out1, 1, in3, 1) = pCm(jo1, ji3);
            jpot(out1, 1, 1, in4) = pCm(jo1, ji4);            
            jpot(in1, out2, 1, 1) = pCm(jo2, ji1);
            jpot(1, out2, in3, 1) = pCm(jo2, ji3);
            jpot(1, out2, 1, in4) = pCm(jo2, ji4);
            jpot(in1, 1, out3, 1) = pCm(jo3, ji1);
            jpot(1, in2, out3, 1) = pCm(jo3, ji2);                                       
            jpot(1, 1, out3, in4) = pCm(jo3, ji4);
            jpot(in1, 1, 1, out4) = pCm(jo4, ji1);
            jpot(1, in2, 1, out4) = pCm(jo4, ji2);                                       
            jpot(1, 1, in3, out4) = pCm(jo4, ji3);
            
            % two in, one out: ra = rel angle (larger means more leftward) 
            jpot(out1, in2, in3, 1) = ...
                (ra(ji2, jo1)>ra(ji3, jo1))*pCm(jo1, ji2) + ...
                (ra(ji2, jo1)<=ra(ji3, jo1))*pCm(jo1, ji3);
            jpot(out1, in2, 1, in4) = ...
                (ra(ji2, jo1)>ra(ji4, jo1))*pCm(jo1, ji2) + ...
                (ra(ji2, jo1)<=ra(ji4, jo1))*pCm(jo1, ji4);
            jpot(out1, 1, in3, in4) = ...
                (ra(ji3, jo1)>ra(ji4, jo1))*pCm(jo1, ji3) + ...
                (ra(ji3, jo1)<=ra(ji4, jo1))*pCm(jo1, ji4);            
            jpot(in1, out2, in3, 1) = ...
                (ra(ji1, jo2)>ra(ji3, jo2))*pCm(jo2, ji1) + ...
                (ra(ji1, jo2)<=ra(ji3, jo2))*pCm(jo2, ji3);            
            jpot(in1, out2, 1, in4) = ...
                (ra(ji1, jo2)>ra(ji4, jo2))*pCm(jo2, ji1) + ...
                (ra(ji1, jo2)<=ra(ji4, jo2))*pCm(jo2, ji4);  
            jpot(1, out2, in3, in4) = ...
                (ra(ji3, jo2)>ra(ji4, jo2))*pCm(jo2, ji3) + ...
                (ra(ji3, jo2)<=ra(ji4, jo2))*pCm(jo2, ji4);              
            jpot(in1, in2, out3, 1) = ...
                (ra(ji1, jo3)>ra(ji2, jo3))*pCm(jo3, ji1) + ...
                (ra(ji1, jo3)<=ra(ji2, jo3))*pCm(jo3, ji2); 
            jpot(in1, 1, out3, in4) = ...
                (ra(ji1, jo3)>ra(ji4, jo3))*pCm(jo3, ji1) + ...
                (ra(ji1, jo3)<=ra(ji4, jo3))*pCm(jo3, ji4); 
            jpot(1, in2, out3, in4) = ...
                (ra(ji2, jo3)>ra(ji4, jo3))*pCm(jo3, ji2) + ...
                (ra(ji2, jo3)<=ra(ji4, jo3))*pCm(jo3, ji4);                         
            jpot(in1, in2, 1, out4) = ...
                (ra(ji1, jo4)>ra(ji2, jo4))*pCm(jo4, ji1) + ...
                (ra(ji1, jo4)<=ra(ji2, jo4))*pCm(jo4, ji2); 
            jpot(in1, 1, in3, out4) = ...
                (ra(ji1, jo4)>ra(ji3, jo4))*pCm(jo4, ji1) + ...
                (ra(ji1, jo4)<=ra(ji3, jo4))*pCm(jo4, ji3); 
            jpot(1, in2, in3, out4) = ...
                (ra(ji2, jo4)>ra(ji3, jo4))*pCm(jo4, ji2) + ...
                (ra(ji2, jo4)<=ra(ji3, jo4))*pCm(jo4, ji3);
            
            % one in, two out 
            jpot(in1, out2, out3, 1) = ...
                (ra(ji1, jo2)>ra(ji1, jo3))*pCm(jo2, ji1)*pB(jo3, 2) + ...
                (ra(ji1, jo2)<=ra(ji1, jo3))*pCm(jo3, ji1)*pB(jo2, 2);
            jpot(in1, out2, 1, out4) = ...
                (ra(ji1, jo2)>ra(ji1, jo4))*pCm(jo2, ji1)*pB(jo4, 2) + ...
                (ra(ji1, jo2)<=ra(ji1, jo4))*pCm(jo4, ji1)*pB(jo2, 2);   
            jpot(in1, 1, out3, out4) = ...
                (ra(ji1, jo3)>ra(ji1, jo4))*pCm(jo3, ji1)*pB(jo4, 2) + ...
                (ra(ji1, jo3)<=ra(ji1, jo4))*pCm(jo4, ji1)*pB(jo3, 2);            
            jpot(out1, in2, out3, 1) = ...
                (ra(ji2, jo1)>ra(ji2, jo3))*pCm(jo1, ji2)*pB(jo3, 2) + ...
                (ra(ji2, jo1)<=ra(ji2, jo3))*pCm(jo3, ji2)*pB(jo1, 2); 
            jpot(out1, in2, 1, out4) = ...
                (ra(ji2, jo1)>ra(ji2, jo4))*pCm(jo1, ji2)*pB(jo4, 2) + ...
                (ra(ji2, jo1)<=ra(ji2, jo4))*pCm(jo4, ji2)*pB(jo1, 2);  
            jpot(1, in2, out3, out4) = ...
                (ra(ji2, jo3)>ra(ji2, jo4))*pCm(jo3, ji2)*pB(jo4, 2) + ...
                (ra(ji2, jo3)<=ra(ji2, jo4))*pCm(jo4, ji2)*pB(jo3, 2);                          
            jpot(out1, out2, in3, 1) = ...
                (ra(ji3, jo1)>ra(ji3, jo2))*pCm(jo1, ji3)*pB(jo2, 2) + ...
                (ra(ji3, jo1)<=ra(ji3, jo2))*pCm(jo2, ji3)*pB(jo1, 2);
            jpot(out1, 1, in3, out4) = ...
                (ra(ji3, jo1)>ra(ji3, jo4))*pCm(jo1, ji3)*pB(jo4, 2) + ...
                (ra(ji3, jo1)<=ra(ji3, jo4))*pCm(jo4, ji3)*pB(jo1, 2);
            jpot(1, out2, in3, out4) = ...
                (ra(ji3, jo2)>ra(ji3, jo4))*pCm(jo2, ji3)*pB(jo4, 2) + ...
                (ra(ji3, jo2)<=ra(ji3, jo4))*pCm(jo4, ji3)*pB(jo2, 2);                         
            jpot(out1, out2, 1, in4) = ...
                (ra(ji4, jo1)>ra(ji4, jo2))*pCm(jo1, ji4)*pB(jo2, 2) + ...
                (ra(ji4, jo1)<=ra(ji4, jo2))*pCm(jo2, ji4)*pB(jo1, 2);
            jpot(out1, 1, out3, in4) = ...
                (ra(ji4, jo1)>ra(ji4, jo3))*pCm(jo1, ji4)*pB(jo3, 2) + ...
                (ra(ji4, jo1)<=ra(ji4, jo3))*pCm(jo3, ji4)*pB(jo1, 2);   
            jpot(1, out2, out3, in4) = ...
                (ra(ji4, jo2)>ra(ji4, jo3))*pCm(jo2, ji4)*pB(jo3, 2) + ...
                (ra(ji4, jo2)<=ra(ji4, jo3))*pCm(jo3, ji4)*pB(jo2, 2);                                    
        otherwise
            error('junction greater than 4')
    end
    
    vars{fk} = jund{k};
    factors{fk} = jpot;

end

%% Geometry factors

nsp = size(pg, 1);
gfactors = cell(nsp + ne, 1);
gvars = cell(nsp + ne, 1);
for k = 1:nsp
    gvars{k} = ne+k;
    gfactors{k} = pg(k, :)';
end
% gnd plan por sol sky
pot = penalty*ones(3,5,5);
pot(1, 1, 1) = 1; % 0-g-g  (format edge-g_left-g_right)
pot(1, 2, 2) = 1; % 0-v-v
pot(1, 3, 3) = 1;
pot(1, 4, 4) = 1;
pot(1, 5, 5) = 1; % 0-s-s
pot(2, :, :) = 1;
pot(2, 1, 1:4) = 0;
pot(2, 5, :) = 0;
pot(3, :, :) = 1;
pot(3, 1:4, 1) = 0;
pot(3, :, 5) = 0;

for k = 1:ne
    gvars{k+nsp} = [k ne+bndinfo.edges.spLR(k, 1) ne+bndinfo.edges.spLR(k, 2)];
    gfactors{k+nsp} = pot;            
end

% add 0.25 penalty for isolated regions, unless outside (right side) is ground
loopind = find(ejunctions(:,1)==ejunctions(:, 2));
for k = loopind'
    gfactors{k+nsp}(2:3, :, 2:end) = gfactors{k+nsp}(2:3, :, 2:end)*0.25;
end

factors = [factors ; gfactors];
vars = [vars ; gvars];