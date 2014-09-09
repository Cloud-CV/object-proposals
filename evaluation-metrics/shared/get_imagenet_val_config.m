function methods = get_method_configs()
% Get properties of all proposal methods. For examples, this includes paths to
% candidate files, intermediate files, and also information about how to sort
% candidates.

% If you want to add your own method, add it at the bottom.

colormap = [ ...
0, 0, 0; ...
228, 229, 97 ; ...
163, 163, 163 ; ...
218, 71, 56 ; ...
219, 135, 45 ; ...
145, 92, 146 ; ...
83, 136, 173 ; ...
135, 130, 174 ; ...
225, 119, 174 ; ...
142, 195, 129 ; ...
138, 180, 66 ; ...
223, 200, 51 ; ...
92, 172, 158 ; ...
177,89,40;
0, 255, 255;
188, 128, 189;
255, 255, 0;
] ./ 256;

 % config = get_config();
 % precomputed_prefix = config.precomputed_candidates;

methods = [];
  %{
   i = numel(methods) + 1;
  methods(i).name = 'LabelTransfer';
  methods(i).short_name = 'LT';
  prefix = ['/home/gneelima/work/data/intermediate/objectProposals/labelTransfer/nonflann'];
  methods(i).candidate_dir = [prefix ];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).best_imagenet_candidates_file = [prefix 'best_candidates_imagenet.mat'];
  methods(i).order = 'none';
  methods(i).abo_voc07_candidates_file=[prefix 'abo_candidates.mat'];
% methods(i).extract = @run_prop;
  methods(i).num_candidates = false;
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = false;
  
  i = numel(methods) + 1;
  methods(i).name = 'Sel.Search';
  methods(i).short_name = 'SS';
  prefix = ['/home/gneelima/Selective_search_imagenet/val/'];
  methods(i).candidate_dir = [prefix ];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).abo_voc07_candidates_file=[prefix 'abo_candidates.mat'];
  methods(i).order = 'ascend';
  methods(i).num_candidates = true;
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = false;
%}
  i = numel(methods) + 1;
  methods(i).name = 'EdgeBoxes';
  methods(i).short_name = 'EB';
  prefix = ['/home/gneelima/work/data/output/objectProposals/edgeBoxes/imagenetBoxesIOU7/'];
  methods(i).candidate_dir = [prefix ];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).abo_voc07_candidates_file=[prefix 'abo_candidates.mat'];
  methods(i).order = 'descend';
  methods(i).extract = @run_edge_boxes;
  methods(i).num_candidates = true;
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = false;
%{   
  i = numel(methods) + 1;
  methods(i).name = 'Edge Boxes 50';
  methods(i).short_name = 'EB50';
  prefix = ['/home/gneelima/work/data/output/objectProposals/edgeBoxes/imagenetBoxesIOU5/'];
  methods(i).candidate_dir = [prefix ];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).abo_voc07_candidates_file=[prefix 'abo_candidates.mat'];
  methods(i).order = 'descend';
  methods(i).num_candidates = true;
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = false;
  
  i = numel(methods) + 1;
  methods(i).name = 'Edge Boxes 90';
  methods(i).short_name = 'EB90';
  prefix = ['/home/gneelima/work/data/output/objectProposals/edgeBoxes/imagenetBoxesIOU9/'];
  methods(i).candidate_dir = [prefix ];
  methods(i).abo_voc07_candidates_file=[prefix 'abo_candidates.mat'];
  methods(i).best_imagenet_candidates_file = [prefix 'best_candidates_imagenet.mat'];
  methods(i).order = 'descend';
  methods(i).is_baseline = false;
 %} 
  % add your own method here:
  if false
  i = numel(methods) + 1;
  methods(i).name = 'The full name of your method';
  methods(i).short_name = 'a very short version of the name';
  prefix = [precomputed_prefix 'ours-wip/'];
  methods(i).candidate_dir = [prefix ];
  methods(i).repeatability_candidate_dir = [prefix 'repeatability_mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).abo_voc07_candidates_file=[prefix 'abo_candidates.mat'];
  methods(i).best_imagenet_candidates_file = [prefix 'best_candidates_imagenet.mat'];
  methods(i).repeatability_matching_file = [prefix 'repeatability_matching.mat'];
  % This specifies how to order candidates so that the first n, are the best n
  % candidates. For example we run a method for 10000 candidates and then take
  % the first 10, instead of rerunning for 10 candidates. Valid orderings are:
  %   none: candidates are already sorted, do nothing
  %   ascend/descend: sort by score descending or ascending
  %   random: random order
  %   biggest/smallest: sort by size of the bounding boxes
  methods(i).order = 'descend';
  % A function pointer to a method that runs your proposal detector.
  methods(i).extract = @run_edge_boxes90;
  % If your method supports sorting this should be empty. If your method has to
  % be rerun for every number of candidates we want, specify the number of
  % candidates here:
  methods(i).rerun_num_candidates = []; % ceil(10 .^ (2:0.5:4));
  % Specifies whether or not your method takes the desired number of candidates
  % as an input.
  % TODO(hosang): Is this actually used anywhere?
  methods(i).num_candidates = true;
  % color for drawing
  methods(i).color = colormap(i,:);
  % This should be false. Is used for drawing baselines dashed.
  methods(i).is_baseline = false;
  end
  
  % do the sorting dance
  sort_keys = [num2cell([methods.is_baseline])', {methods.name}'];
  for i = 1:numel(methods)
    sort_keys{i,1} = sprintf('%d', sort_keys{i,1});
  end
  [~,idx] = sortrows(sort_keys);
  for i = 1:numel(methods)
    methods(idx(i)).sort_key = i;
  end
end
