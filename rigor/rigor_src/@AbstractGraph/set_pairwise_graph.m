function set_pairwise_graph(abst_obj)
% this function takes the pixel-wise precomputed edge values, and compute
% the superpixel-to-superpixel edge potentials. Since AbstractGraph is a
% handle class, it is passed as a reference and hence you can make the
% changes to it directly
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

    % precomputed pairwise edge values
    precomputed_edge_vals = abst_obj.seg_obj.edge_vals;

    edge_vals = ...
        AbstractGraph.get_pairwise_capacities(precomputed_edge_vals, ...
                                abst_obj.graph_pairwise_sigma, ...
                                abst_obj.graph_pairwise_contr_weight, ...
                                abst_obj.graph_pairwise_potts_weight);
    
    % accumulate values for each edgelet (edge lying across two SPs)
    abst_obj.edge_vals = ...
        accumarray(abst_obj.seg_obj.sp_data.edgelet_ids, edge_vals);

    % pairwise normalization by edge length
%     edgelet_lens = accumarray(edgelet_ids, ones(size(edgelet_ids)));
%     accum_val = accum_val ./ edgelet_lens;

    abst_obj.edge_vals = round(abst_obj.edge_vals * ...
                               abst_obj.graph_pairwise_multiplier);
    
    assert(length(abst_obj.edge_vals) == ...
           size(abst_obj.seg_obj.sp_data.edgelet_sp,1), ...
           'Something went wrong with superpixel edgelets');
end