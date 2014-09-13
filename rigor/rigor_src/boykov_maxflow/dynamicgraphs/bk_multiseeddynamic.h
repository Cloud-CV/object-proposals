// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#ifndef _BK_MULTISEEDDYNAMIC_H_
#define _BK_MULTISEEDDYNAMIC_H_

#include "bk_dynamicgraphs.h"


void update_graph_gen_fg_remove_list(GraphType* const g_precomp,
                                     GraphType::SrcSeedList* const seed_remove_list,
                                     const GraphType::FGSeedsType& fg_seeds,
                                     const fgseedmaptype& fg_seed_map,
                                     const size_t& num_vars,
                                     const size_t& num_params,
                                     const unarycaptype* const nonlambda_s,
                                     const unarycaptype* const nonlambda_t,
                                     const unarycaptype* const orig_nonlambda_s,
                                     const unarycaptype* const orig_nonlambda_t,
                                     const unarycaptype* const lambda_s,
                                     const unarycaptype* const lambda_t,
                                     const unarycaptype* const orig_lambda_s,
                                     const unarycaptype* const orig_lambda_t,
                                     const lambdaparamtype* const lambda_range,
                                     resulttype* const cuts,
                                     unsigned int& in_src_cut,
                                     const unsigned int init_lambda_idx,
                                     const unsigned int repl_lambda_idx,
                                     const int keep_src_id)
{
  seed_remove_list[0].clear();
  seed_remove_list[1].clear();
  
  fgseedmaptype::const_iterator it;
  unarycaptype s_cap, t_cap;

  /* iterate over all seeds to update the graph */
  for (GraphType::node_id var_i = 0; var_i < num_vars; ++var_i) {
    int fg_node_id = INVALID_SRC_ID;

    it = fg_seed_map.find(var_i);
    if (it != fg_seed_map.end())
      fg_node_id = it->second.first;

    if (fg_node_id == keep_src_id) {
      /* no need to change anything here - this was a seed and still is a seed*/
      //std::cout << keep_src_id << ": Keeping src: " << var_i << std::endl;
    } else if (fg_node_id != keep_src_id && fg_node_id != INVALID_SRC_ID) {
      /* seeds from other graphs which need to be converted */
      int fg_src_seed_idx = it->second.second;
      s_cap = fg_seeds[fg_node_id][fg_src_seed_idx].second.first;
      t_cap = fg_seeds[fg_node_id][fg_src_seed_idx].second.second;
      seed_remove_list[0].push_back(
          GraphType::SrcSeedNode(var_i, GraphType::NodeCap(s_cap, t_cap)));

      s_cap = nonlambda_s[var_i] +
          lambda_range[repl_lambda_idx]*lambda_s[var_i];
      t_cap = nonlambda_t[var_i] +
          lambda_range[num_params-repl_lambda_idx-1]*lambda_t[var_i];
      seed_remove_list[1].push_back(
          GraphType::SrcSeedNode(var_i, GraphType::NodeCap(s_cap, t_cap)));

      /* only mark the variable if it had a non-negative source capacity
       * because otherwise it will be in the T tree anyways */
      /*if (s_cap > 0)
        g_precomp->mark_node(var_i);*/
    } else {
      // all other variables
      /* the previous unary capacities */
      unarycaptype s_cap_prv = orig_nonlambda_s[var_i] +
          lambda_range[init_lambda_idx]*orig_lambda_s[var_i];
      unarycaptype t_cap_prv = orig_nonlambda_t[var_i] +
          lambda_range[num_params-init_lambda_idx-1]*orig_lambda_t[var_i];
      unarycaptype old_cap_diff = s_cap_prv - t_cap_prv;

      /* new unary capacities */
      unarycaptype s_cap = nonlambda_s[var_i] +
          lambda_range[repl_lambda_idx]*lambda_s[var_i];
      unarycaptype t_cap = nonlambda_t[var_i] +
          lambda_range[num_params-repl_lambda_idx-1]*lambda_t[var_i];
      unarycaptype new_cap_diff = s_cap - t_cap;

      // reparameterize the unary
      g_precomp->reparam_unary(var_i, old_cap_diff, new_cap_diff);
    }
  }
}

GraphType* multiseeddyn_init(const size_t& num_seeds,
                             const size_t& num_vars,
                             const size_t& num_pairwise_edges,
                             const size_t& num_params,
                             const unarycaptype* const nonlambda_s,
                             const unarycaptype* const nonlambda_t,
                             const unarycaptype* const lambda_s,
                             const unarycaptype* const lambda_t,
                             const lambdaparamtype* const lambda_range,
                             const pairwisecaptype* const pairwise_edges,
                             GraphType::FGSeedsType* const fg_seeds,
                             fgseedmaptype* const fg_seed_map,
                             const int& precomp_lambda_idx)
{
  /* get all the seed variables i.e.  */
  gather_seed_vars(num_seeds, num_vars, fg_seeds, fg_seed_map, nonlambda_s,
                   nonlambda_t);

  /* construct the precomputation graph */
  GraphType* g_precomp = new GraphType(num_vars, num_pairwise_edges);
  g_precomp->add_node(num_vars);

  fgseedmaptype::iterator it;

  /* add unary edges */
  for (GraphType::node_id var_i = 0; var_i < num_vars; ++var_i) {
    /* see if this variable belongs to one of the seeds */
    int fg_node_id = INVALID_SRC_ID;

    it = fg_seed_map->find(var_i);
    if (it != fg_seed_map->end())
      fg_node_id = it->second.first;

    /* if a bg node in all seed graphs then only add the unary capacity to the
       sink as given in the FIRST GRAPH */
    if (fg_node_id == INVALID_SRC_ID) {
      unarycaptype s_cap = nonlambda_s[var_i] +
          lambda_range[precomp_lambda_idx]*lambda_s[var_i];
      unarycaptype t_cap = nonlambda_t[var_i] +
          lambda_range[num_params-precomp_lambda_idx-1]*lambda_t[var_i];

      g_precomp->add_tweights(var_i, s_cap, t_cap);
    } else {
      /* if a fg node add both sink and src unaries (the src unary is usually a
       * large value) */
      int fg_src_seed_idx = it->second.second;
      unarycaptype s_cap = (*fg_seeds)[fg_node_id][fg_src_seed_idx].second.first;
      unarycaptype t_cap = (*fg_seeds)[fg_node_id][fg_src_seed_idx].second.second;
      g_precomp->add_tweights(var_i, s_cap, t_cap);
    }

    g_precomp->set_node_source_idx(var_i, fg_node_id);
  }

  /* add pairwise capacity edges */
  const pairwisecaptype* const pairwise_edges_v = pairwise_edges + num_pairwise_edges;
  const pairwisecaptype* const pairwise_edges_cap = pairwise_edges_v + num_pairwise_edges;

  for (size_t edge_i=0; edge_i < num_pairwise_edges; ++edge_i) {
    g_precomp->add_edge((GraphType::node_id)pairwise_edges[edge_i]-1,
                        (GraphType::node_id)pairwise_edges_v[edge_i]-1,
                        pairwise_edges_cap[edge_i], pairwise_edges_cap[edge_i]);
  }
/*
  std::vector<int> num_graph_seeds(num_seeds, 0);
    int bg_t_vars = 0;
    for (GraphType::node_id var_i = 0; var_i < num_vars; ++var_i) {
      int seed_id = g_precomp->get_node_source_idx(var_i);
      if (seed_id == INVALID_SRC_ID)
        ++bg_t_vars;
      else {
        ++num_graph_seeds[seed_id];
      }
    }
    for (int seed_i=0; seed_i < num_seeds; ++seed_i) {
      std::cout << "seed " << seed_i << " : num : " << num_graph_seeds[seed_i] <<  " | " << (*fg_seeds)[seed_i].size() << std::endl;
    }
    std::cout << "T: " << bg_t_vars << std::endl;
*/

  /* do the maxflow for the multi-source tree grap - this will produce the
   * precomputation graph */
  g_precomp->maxflow();

/*
  num_graph_seeds.assign(num_seeds, 0);
  bg_t_vars = 0;
  for (GraphType::node_id var_i = 0; var_i < num_vars; ++var_i) {
    int seed_id = g_precomp->get_node_source_idx(var_i);
    if (seed_id == INVALID_SRC_ID)
      ++bg_t_vars;
    else {
      ++num_graph_seeds[seed_id];
    }
  }
  for (int seed_i=0; seed_i < num_seeds; ++seed_i) {
    std::cout << "seed " << seed_i << " : num : " << num_graph_seeds[seed_i] << std::endl;
  }
  std::cout << "T: " << bg_t_vars << std::endl;
*/

  return g_precomp;
}

struct ParallelMultiseedDynInit {
  const size_t num_seeds, num_vars, num_pairwise_edges, num_params,
               num_graph_types;
  const unarycaptype* const nonlambda_s;
  const unarycaptype* const nonlambda_t;
  const unarycaptype* const lambda_s;
  const unarycaptype* const lambda_t;
  const lambdaparamtype* const lambda_range;
  const pairwisecaptype* const pairwise_edges;
  const graphtypeidxtype* const graph_type_start_idx;
  const std::vector<int>* const precomp_lambda_idx;
  std::vector<GraphType::FGSeedsType>* const fg_seeds;
  std::vector<fgseedmaptype>* const fg_seed_map;
  std::vector<GraphType*>* const gs_precomp;

  void operator()(const tbb::blocked_range<size_t>& range) const {
    size_t num_curr_seeds;

    /* get all precomputation graphs */
    for (size_t graph_type_idx = range.begin(); graph_type_idx != range.end();
         ++graph_type_idx) {
      /* get the number of seeds in this graph and the starting index */
      graphtypeidxtype start_idx = graph_type_start_idx[graph_type_idx];
      if (graph_type_idx < num_graph_types-1)
        num_curr_seeds = graph_type_start_idx[graph_type_idx+1] - start_idx;
      else
        num_curr_seeds = num_seeds - start_idx + 1;

      --start_idx;
      unsigned long offset = start_idx*num_vars;

      /* create and store the precomputation graph */
      GraphType* g_precomp = multiseeddyn_init(num_curr_seeds, num_vars,
                                               num_pairwise_edges, num_params,
                                               nonlambda_s+offset,
                                               nonlambda_t+offset,
                                               lambda_s+offset,
                                               lambda_t+offset, lambda_range,
                                               pairwise_edges,
                                               &((*fg_seeds)[graph_type_idx]),
                                               &((*fg_seed_map)[graph_type_idx]),
                                               (*precomp_lambda_idx)[graph_type_idx]);

      (*gs_precomp)[graph_type_idx] = g_precomp;
    }
  }

  ParallelMultiseedDynInit(const size_t& num_seeds, const size_t& num_vars,
                           const size_t& num_pairwise_edges,
                           const size_t& num_params,
                           const size_t& num_graph_types,
                           const unarycaptype* const nonlambda_s,
                           const unarycaptype* const nonlambda_t,
                           const unarycaptype* const lambda_s,
                           const unarycaptype* const lambda_t,
                           const lambdaparamtype* const lambda_range,
                           const pairwisecaptype* const pairwise_edges,
                           const graphtypeidxtype* const graph_type_start_idx,
                           const std::vector<int>* const precomp_lambda_idx,
                           std::vector<GraphType::FGSeedsType>* const fg_seeds,
                           std::vector<fgseedmaptype>* const fg_seed_map,
                           std::vector<GraphType*>* const gs_precomp)
  : num_seeds(num_seeds), num_vars(num_vars), num_graph_types(num_graph_types),
    num_pairwise_edges(num_pairwise_edges), num_params(num_params),
    nonlambda_s(nonlambda_s), nonlambda_t(nonlambda_t), lambda_s(lambda_s),
    lambda_t(lambda_t), lambda_range(lambda_range),
    pairwise_edges(pairwise_edges), graph_type_start_idx(graph_type_start_idx),
    precomp_lambda_idx(precomp_lambda_idx), fg_seeds(fg_seeds),
    fg_seed_map(fg_seed_map), gs_precomp(gs_precomp) {
  }
};


#endif // _BK_MULTISEEDDYNAMIC_H_
