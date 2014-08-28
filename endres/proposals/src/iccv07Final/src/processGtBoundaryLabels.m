function bndinfo = processGtBoundaryLabels(bndinfo)
%
% bndinfo = labelBoundaries2(bndinfo)
%
% Adds edges.boundaryType(nde) for each directed edge
%      -1: borders an unlabeled region (or image border)
%       0: not an occluding boundary
%       1: ground occludes
%       2: planar occludes
%       3: porous occludes
%       4: solid occludes
%       5: distant occludes

for f = 1:numel(bndinfo)

    % Create occlusion matrix
    % sky is always occluded;  ground only occludes sky; 
    % rest determined by order of listing (occluding objects listed first)
    nt = numel(bndinfo(f).type);
    occlusionMatrix = false(nt, nt);
    occlusionMatrix(1, 2) = true; % ground occludes sky
    for k = 3:nt
        occlusionMatrix(k, 1:2) = true; % everything occludes ground and sky
        occlusionMatrix(k, k+1:end) = true;
    end
    
    ne = bndinfo(f).ne;
    nde = ne*2; % twice as many directed as undirected edges       
    
    spLR = bndinfo(f).edges.spLR; 
    spLR = [spLR ; spLR(:, [2 1])];
    rlabels = bndinfo(f).labels; % object number for each superpixel
    types = bndinfo(f).type;         
    
    blabels = zeros(nde, 1);
    type2b = [1 0 2 3 4 5]; % map from geometry type to boundary type
    
    for kd = 1:nde

        sp = spLR(kd, :);       
        
        if any(sp==0) || any(rlabels(sp)==0)
            blabels(kd) = -1;
        else
            o1 = rlabels(sp(1));  o2 = rlabels(sp(2));
            if occlusionMatrix(o1, o2)
                blabels(kd) = type2b(types(o1));
            else
                blabels(kd) = 0;
            end
        end
    end
    
    bndinfo(f).edges.boundaryType = blabels;
    
end        

