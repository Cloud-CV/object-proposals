function [final_regions res] = processReg2Proposals(image_data, region_data)

function_root = which('generate_proposals.m');
function_root = function_root(1:end-length('generate_proposals.m'));

load(fullfile(function_root, 'classifiers', 'pairwise_classifier_final.mat'), 'classifier');

regions = region_data.regions;
bndinfo_all = image_data.occ.bndinfo_all;
bndinfo = bndinfo_all{1};

pb1 = image_data.occ.pb1;
pb2 = image_data.occ.pb2;

% OB stuff
pb_t = pb1 + pb2;
pb_a = 0.01 + 0.99*pb_t; % avoid zero cost edges


%%%%%%%%%%%% Edge pairwise constraints %%%%%%%%%%%
flipped = bndinfo.edges.spLR(:,1) > bndinfo.edges.spLR(:,2);
edges_sorted = bndinfo.edges.spLR;
edges_sorted(flipped, [1 2]) = edges_sorted(flipped, [2 1]);

[pairs dk pair_ind] = unique(edges_sorted, 'rows');
sp_counts = hist(double(pairs(:)), double(1:max(pairs(:))));
sp_counts_inv = 1./sp_counts;
sp_pair_norm = sum(sp_counts_inv(pairs), 2);
pw_pb = zeros(size(pairs,1), 1);

for i = 1:size(pairs,1)
   edge_inds = find(pair_ind == i);
   pw_pb(i) = mean(pb_a(edge_inds));
end

pw_pb_norm = pw_pb.^sp_pair_norm;

edges_pb_pw = pairs;

region_object = 1./(1+exp(-region_data.predictions(:, 6)));
region_purity = 1./(1+exp(-region_data.predictions(:, 5)));

[prob sinds] = sort(region_object.*region_purity, 'descend');

sp_pure_obj_sum = region_to_sp(bndinfo, regions, 'accum', region_object.*region_purity);
sp_pure_sum = region_to_sp(bndinfo, regions, 'accum', region_purity);

weighted_sp_po = sp_pure_obj_sum./sp_pure_sum;

sind = sinds(1);

num_seeds = length(prob);

feats_all = segmentPairFeat(1, [], region_data);

u_energy_all = test_boosted_dt_mc(classifier, feats_all);

% This is not symmetric, each row represents a source region:
u_energy_all = reshape(u_energy_all, numel(regions), numel(regions)); 
u_p_all = 1./(1+exp(-u_energy_all));

tradeoffs = [0 0.05 0.1 0.5 1 2 5 10];
biases = [-2 -1.5 -1 -0.5 0 0.5 1];%'*ones(1,bndinfo.nseg);

results = repmat(struct([]), numel(tradeoffs)*numel(biases)*num_seeds, 1);
r_ind = 1;

start = tic;

for i = 1:num_seeds
   sind = sinds(i);
   if(toc(start)>5)
      fprintf('\t%d/%d\n', i, num_seeds);
      start = tic;
   end

   u_p = u_p_all(sind,:)';
   
   u_pok_unnorm = region_to_sp(bndinfo, regions, 'accum', u_p.*region_purity); 
   u_pok_norm = u_pok_unnorm./sp_pure_sum; % apparently doesn't make much difference 
   
   labels = region_to_sp(bndinfo, regions(sind), 'max', 1) + 1;%1 + zeros(size(u_pok, 1), 1);

   for tr = 1:length(tradeoffs)
      for b = 1:numel(biases)
         tradeoff = tradeoffs(tr);
         bias = biases(b);

         do_cut_fast

         results(r_ind).tradeoff = tradeoff;
         results(r_ind).bias = bias;
         results(r_ind).sind = sind;
         results(r_ind).energy = energy;
         results(r_ind).regions = find(lab2==2);
         
         results(r_ind).seed_prob = region_object(sind);
         results(r_ind).seed_w_prob = region_object(sind).*region_purity(sind);
         r_ind = r_ind + 1;
      end
   end
end

sp_areas_struct = regionprops(bndinfo.wseg, 'Area', 'BoundingBox');
sp_areas = [sp_areas_struct.Area];
sp_bb = cat(1,sp_areas_struct.BoundingBox);
sp_bb = [sp_bb(:,1) sp_bb(:,2) (sp_bb(:,1) + sp_bb(:,3)) (sp_bb(:,2) + sp_bb(:,4))];

regions = {results.regions};
%%%%%%%%%%%%% Prune Regions %%%%%%%%%%%%%%%%%%%%%%
%[orig_regions orig2unique] = get_unique_regions(regions, bndinfo.nseg); 
% Remove redundant regions (nms with threshold of 100%)
orig_regions = region_nms_fast(regions, ones(size(regions)), 1, sp_areas, bndinfo);

% for proposals with disconnected components, also propose each component as a region
new_regions = split_regions(orig_regions, bndinfo, sp_areas);

% remove redundant regions again (slightly more aggressive this time)
final_regions = region_nms_fast(new_regions, ones(size(new_regions)), 0.98, sp_areas, bndinfo);

% Remove empty regions
remove = zeros(size(final_regions));
for i = 1:length(final_regions)
   if(numel(final_regions{i})==0)
      remove(i) = 1;
   end
end
final_regions = final_regions(~remove);

res.prop_bbox = get_region_bbox(final_regions, sp_bb);
res.orig_prop_bbox = get_region_bbox(orig_regions, sp_bb);

res.num_regions = numel(final_regions);
res.orig_num_regions = numel(orig_regions);


res.final_regions = final_regions;

