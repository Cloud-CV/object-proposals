function [feats timing] = segment_pairing_features(image_data, region_data, sinds)

regions = region_data.regions;
Xapp = region_data.Xapp;

if(~exist('sinds', 'var'))
   sinds = 1:length(regions);
end

%Compute pairwise distances
c_chisq = slmetric_pw(cat(1,Xapp(sinds).color)', cat(1,Xapp.color)', 'chisq'); % 
c_hint = slmetric_pw(cat(1,Xapp(sinds).color)', cat(1,Xapp.color)', 'intersectdis'); % 

t_chisq = slmetric_pw(cat(1,Xapp(sinds).texture)', cat(1,Xapp.texture)', 'chisq'); % 
t_hint = slmetric_pw(cat(1,Xapp(sinds).texture)', cat(1,Xapp.texture)', 'intersectdis'); % 

%bmap = pb1 + pb2;
bound_max = zeros(numel(sinds), numel(regions));
bound_sum = zeros(numel(sinds), numel(regions));

bmap = double(image_data.occ.bmap);
for ra = sinds
   for rb = 1:numel(regions)
      if(ra==rb)
         % Some properties may not be well defined for identical segments
         continue
      end
      
      vals = SegInMat(bmap, Xapp(ra).cm(2), Xapp(ra).cm(1), Xapp(rb).cm(2), Xapp(rb).cm(1));

      [bound_max(ra,rb)] = max(vals);
      [bound_sum(ra,rb)] = sum(vals);
   end
end

feats.c_chisq = c_chisq;
feats.c_hint = c_hint;
feats.t_chisq = t_chisq;
feats.t_hint = t_hint;
feats.bound_max = bound_max;
feats.bound_sum = bound_sum;
