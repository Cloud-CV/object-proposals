function [X Xapp] = getSimpleSubregionFeatures(image_data, regions, Pobject, Psolid)
% X = getSimpleSubregionFeatures(regions, bndinfo, pb1, pb2, Pobject,
% Psolid)
%
% Output:
%  X:
%     1- 2: mean/max Poccludes exterior
%     3- 4: mean/max Poccluded exterior
%     5- 6: mean/max Pboundary interior
%     7- 10: min/mean/max, max-min Pobject
%    11-14: min/mean/max, max-min Psolid
%    15-16: mean/max Pboundary exterior 


X = zeros(numel(regions), 16);

bndinfo = image_data.occ.bndinfo_all{1};

stats = regionprops(bndinfo.wseg, 'Area', 'PixelIdxList');
area = cat(1, stats.Area);
idx = {stats.PixelIdxList};

pobj = getRegionMean(idx, Pobject);
psol = getRegionMean(idx, Psolid);

pb1 = image_data.occ.pb1;
pb2 = image_data.occ.pb2;

Pbnd = pb1 + pb2;

Poccludes = zeros(size(pb1));  
Poccluded = zeros(size(pb1)); 
Pboth = zeros(size(pb1)); 
for r = 1:numel(regions)
    
    % boundary features
    left = ismember(bndinfo.edges.spLR(:, 1), regions{r});
    right = ismember(bndinfo.edges.spLR(:, 2), regions{r});

    bnd = (left & ~right) | (right & ~left);     
    
    ind1 = left & ~right;
    ind2 = right & ~left;
          
    Poccludes(ind1) = pb1(ind1);
    Poccludes(ind2) = pb2(ind2);
      
    Poccluded(ind1) = pb2(ind1);
    Poccluded(ind2) = pb1(ind2);        

    extbnd = ind1 | ind2;    
    intbnd = left & right;
    
    if any(extbnd)
        X(r, 1) = mean(Poccludes(extbnd));
        X(r, 2) = max(Poccludes(extbnd));
            
        X(r, 3) = mean(Poccluded(extbnd));
        X(r, 4) = max(Poccluded(extbnd));

        X(r, 15) = mean(Pbnd(extbnd));
        X(r, 16) = max(Pbnd(extbnd));
    end
    
    if any(intbnd)
        X(r, 5) = mean(Pbnd(intbnd));
        X(r, 6) = max(Pbnd(intbnd));
    end
     
    % region features    
    X(r, 7) = min(pobj(regions{r}));
    X(r, 8) = mean(pobj(regions{r}));
    X(r, 9) = max(pobj(regions{r}));
    X(r, 10) = X(r, 9)-X(r, 7);
    
    X(r, 11) = min(psol(regions{r}));
    X(r, 12) = mean(psol(regions{r}));
    X(r, 13) = max(psol(regions{r}));    
    X(r, 14) = X(r, 13)-X(r, 11);
end

if(nargout>1)
stats = regionprops(bndinfo.wseg, 'Area', 'PixelIdxList','Centroid', 'BoundingBox');
area = cat(1, stats.Area);
cms = cat(1,stats.Centroid);
idx = {stats.PixelIdxList};
bboxes_i = cat(1, stats.BoundingBox);
bboxes = [bboxes_i(:, [1 2]),  bboxes_i(:, [1 2])+ bboxes_i(:, [3 4])];


% Compute unnormalized histograms for superpixels
c_hist = double(getRegionHistogram(bndinfo.wseg, image_data.colorim, 128)); % region x hist
t_hist = double(getRegionHistogram(bndinfo.wseg, image_data.textonim, 256));

Xapp = repmat(struct('cm',[], 'color', [], 'texture',[], 'bbox', []), numel(regions),1);

for r = 1:numel(regions)
    
   areas_t = area(regions{r});
   total_area = sum(areas_t);
   % Compute center of mass (for pairwise features)
   Xapp(r).cm = 1/total_area * areas_t'*cms(regions{r},:); 

   % Compute histograms
   Xapp(r).color = 1/total_area * sum(c_hist(regions{r}, :),1);
   Xapp(r).texture = 1/total_area * sum(t_hist(regions{r}, :),1);
   Xapp(r).bbox = [min(bboxes(regions{r}, 1)) min(bboxes(regions{r}, 2)), max(bboxes(regions{r}, 3)), max(bboxes(regions{r}, 4))];
end

end
