function ranking_feats = getRegionAppearance(image_data, final_regions)

function_root = which('generate_proposals.m');
function_root = function_root(1:end-length('generate_proposals.m'));

load(fullfile(function_root,'classifiers','subregionClassifier_mix.mat'), 'classifier')

%load(fullfile(sprintf('%s/tc2/', dataset), [bn '_tc']),'textonim','colorim');
%load(fullfile(sprintf('%s/bg', dataset), [bn '_bg']), 'object_maps');
%load(fullfile(sprintf('%s/occlusion', dataset), [bn '_occlusion']),'gconf');

bndinfo_all = image_data.occ.bndinfo_all;
bndinfo = bndinfo_all{1};

pb1 = image_data.occ.pb1;
pb2 = image_data.occ.pb2;

surface_maps = image_data.gconf;
object_maps = image_data.bg;

Pobject = 1-object_maps;
Pobject = Pobject / max(Pobject(:));
Psolid = surface_maps(:, :, 5);
Psolid = Psolid/max(Psolid(:));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
app1 = getSubregionFeatures(image_data, final_regions, Pobject, Psolid);

p_obj =  test_boosted_dt_mc(classifier.pure, app1);
p_pure = test_boosted_dt_mc(classifier.object, app1);

feats_all2 = [app1, p_obj, p_pure];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spLR = bndinfo.edges.spLR;
n_sps = bndinfo.nseg;

c_hist = double(getRegionHistogram(bndinfo.wseg, image_data.colorim, 128))'; % region x hist
t_hist = double(getRegionHistogram(bndinfo.wseg, image_data.textonim, 256))';

c_hist_sp = c_hist;
t_hist_sp = t_hist;

inds = double([spLR(:,[1 2]); spLR(:, [2 1]); repmat([1:n_sps]', 1, 2)]);
adjacency = (accumarray(inds, ones(size(inds,1), 1), [n_sps n_sps]));
adjacency = sign(adjacency);

shortest_paths = graphallshortestpaths(sparse(adjacency), 'Directed', 1);
shortest_paths_sp = sparse(shortest_paths<=3); 
c_hist_dist = zeros(length(final_regions), 2);
t_hist_dist = zeros(length(final_regions), 2);


whole_c_hist = sum(c_hist,2);
whole_t_hist = sum(t_hist,2);


imarea = numel(bndinfo_all{1}.wseg);
for i = 1:length(final_regions)
   % Compute color/texture similarity
   % Find minimum distance in graph to proposal
   inds = false(bndinfo.nseg, 1);
   inds(final_regions{i}) = 1;

   leq3 = any(shortest_paths_sp(:,inds)>0,2);
   eq0 = inds;
   % Color

   if(mean(eq0)>0.5)
      c_hist_all = sum(c_hist(:, ~eq0), 2);
      c_hist_all = sum(c_hist_sp(:, ~eq0), 2);
      c_hist_region = whole_c_hist - c_hist_all;
   else
      c_hist_region = sum(c_hist(:, eq0), 2);
      c_hist_region = sum(c_hist_sp(:, eq0), 2);
      c_hist_all = whole_c_hist - c_hist_region;
   end

   c_hist_region = c_hist_region/sum(c_hist_region);
   c_hist_all = c_hist_all/sum(c_hist_all);

   c_hist_3 = sum(c_hist(:, ~eq0 & leq3), 2);
   c_hist_3 = c_hist_3/sum(c_hist_3);

   % Texture

   if(mean(eq0)>0.5)
      t_hist_all = sum(t_hist(:, ~eq0), 2);
      t_hist_region = whole_t_hist - t_hist_all;
   else
      t_hist_region = sum(t_hist(:, eq0), 2);
      t_hist_all = whole_t_hist - t_hist_region;
   end

   t_hist_region = t_hist_region/sum(t_hist_region);
   t_hist_all = t_hist_all/sum(t_hist_all);

   t_hist_3 = sum(t_hist(:, ~eq0 & leq3), 2);
   t_hist_3 = t_hist_3/sum(t_hist_3);
   
   % Distances....
   c = [c_hist_3, c_hist_all];
   c(isnan(c)) = 1/size(c,1);
   t = [t_hist_3, t_hist_all];
   t(isnan(t)) = 1/size(t,1);

   c_hist_dist(i,:) = slmetric_pw(c_hist_region, c, 'intersectdis');
   t_hist_dist(i,:) = slmetric_pw(t_hist_region, t, 'intersectdis');
end

ranking_feats = [feats_all2, c_hist_dist, t_hist_dist];

