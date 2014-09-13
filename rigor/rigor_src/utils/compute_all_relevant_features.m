% @authors:     Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function s_feat = compute_all_relevant_features( sp_seg, edge_graph )
% somehow, all the rest are computed on a halfed image, while the last one
% is on full image...
    s_feat = zeros(max(sp_seg(:)), 6);
%    sp_seg_rszd = imresize(sp_seg,0.5,'nearest');
    [cent, bb, area, perim, secondorder] = superpix_regionprops(uint16(sp_seg));
    bb = double(bb);
    bb(:,1:2) = bb(:,1:2) - 0.5;
    bb(:,3:4) = bb(:,3:4) + 0.5;
    % Left and top both have -0.5 as per MATLAB convention
    s_feat(:,1:2) = double(bb(:,1:2));
    % Eccentricity is a bit tricky...
    % Now the secondorder information is non-central, to get centralized
    % moments we need to use (x - centx)^2 = x^2 - 2 x*centx + centx^2
    % but \sum x /N = centx, therefore we get (x-centx)^2 = secondorder_x - 2
    % centx * centx * N + N * centx * centx = secondorder_x - N * centx *
    % centx
    %1/12 is the normalized second central moment of a pixel with unit length.
    uxx = secondorder(:,1) ./ single(area) - cent(:,1).^2 + 1/12;
    uyy = secondorder(:,2) ./ single(area) - cent(:,2).^2 + 1/12;
    % for uxy, we compute (x - centx) (y-centy)  = xy - centx y - centy x -
    % centx centy, using the same idea we can get that is xy - N centx
    % centy
    uxy = secondorder(:,3) ./ single(area) - cent(:,1) .* cent(:,2);
    common = sqrt((uxx - uyy).^2 + 4*uxy.^2);
    MajorAxisLength =  2*sqrt(2)*sqrt(uxx + uyy + common);
    MinorAxisLength = 2*sqrt(2)*sqrt(uxx + uyy - common);
    Eccentricity = 2*sqrt((MajorAxisLength/2).^2 - (MinorAxisLength/2).^2) ./ MajorAxisLength;
    s_feat(:,3) = Eccentricity;
    % Extent, area / bounding box area
    s_feat(:,4) = single(area) ./ single((bb(:,4) - bb(:,2)) .* (bb(:,3) - bb(:,1)));
    % Perimeter
    s_feat(:,5) = perim;
    s_feat(:,6) = sum(edge_graph,2);
    % Left here commented for verification of correctness
%     for i=1:max(sp_seg(:))
% %          s = regionprops(sp_seg==i,'BoundingBox','Eccentricity','EquivDiameter','Extent','Perimeter');
% %          s = s(1);
% %          s_feat(i,1:5) = [s.BoundingBox(1) s.BoundingBox(2) s.Eccentricity s.Extent s.Perimeter];
% %         % Inter-contour energy, change this just to superpixel boundary
%         % energy
%         all_bw = imdilate(sp_seg==i, ones(5,5)) & imdilate(~(sp_seg==i), ones(5,5));
%         s_feat(i,6) = sum(pb_thin(all_bw));
%     end
end
