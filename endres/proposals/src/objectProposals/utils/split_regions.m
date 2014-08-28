function new_regions = split_regions(regions, bndinfo, sp_areas)

spLR = bndinfo.edges.spLR;

n_sps = bndinfo.nseg;

if(iscell(regions))
   % get overlapping regions
   overlapping = [];

   sp_map = zeros(numel(regions), n_sps);
                  
   for prop = 1:length(regions)
      sp_map(prop,regions{prop}) = 1;
   end
else
   sp_map = regions;
end


inds = double([spLR(:,[1 2]); spLR(:, [2 1]); repmat([1:n_sps]', 1, 2)]);

%sp_map_sparse = sparse(sp_map);
%sparse_adjacency = sparse(inds(:,1), inds(:,2), ones(2*size(spLR,1), 1));
adjacency = (accumarray(inds, ones(size(inds,1), 1), [n_sps n_sps]));
%adjacency_s = sparse(accumarray(inds, ones(size(inds,1), 1), [n_sps n_sps]));

[adjacency_x adjacency_y adjacency_val] = find(adjacency);

new_regions = cell(size(sp_map,1), 1);
new_r_ind = 1;
tic;
for i = 1:size(sp_map,1)
   sp_inds = find(sp_map(i, :));
%   sub_graph = sparse(adjacency(sp_inds, sp_inds));

   ok = ismember_sorted(adjacency_x, sp_inds) & ismember_sorted(adjacency_y, sp_inds);
   ind = zeros(max(adjacency_x),1);
   ind(sp_inds) = 1:length(sp_inds);
   sub_graph = sparse(ind(adjacency_x(ok)), ind(adjacency_y(ok)), adjacency_val(ok), length(sp_inds), length(sp_inds));

   [conn1 comps1] = graphconncomp(sub_graph, 'Directed', true);


   
   if(conn1 > 1)
      if(toc>1)      
         fprintf('%d (%d/%d)\n',new_r_ind, i, size(sp_map,1) );
         tic;
      end         

      for j = 1:conn1
         if(new_r_ind>=numel(new_regions))
            fprintf('growing\n')
            new_regions{2*end}= [];
         end
         if(sum(sp_areas(sp_inds(comps1==j)))>(24*24))
            new_regions{new_r_ind} = sp_inds(comps1==j);
            new_r_ind = new_r_ind+1;
         end
      end 
%      pause
   else
      if(new_r_ind>=numel(new_regions))
         fprintf('growing\n')
         new_regions{2*end}= [];
      end
   
      new_regions{new_r_ind} = sp_inds;
      new_r_ind = new_r_ind+1;
   %      pause(0.3)
   end
      
end

new_regions(new_r_ind+1:end) = [];


