// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "bk_dynamicgraphs.h"

void kohli_param_maxflow(const size_t& num_vars,
                         const size_t& num_pairwise_edges,
                         const size_t& num_params,
                         const unarycaptype* const nonlambda_s,
                         const unarycaptype* const nonlambda_t,
                         const unarycaptype* const lambda_s,
                         const unarycaptype* const lambda_t,
                         const lambdaparamtype* const lambda_range,
                         const pairwisecaptype* const pairwise_edges_u,
                         resulttype* const cuts,
                         secslisttype* const graphconst_times,
                         secslisttype* const maxflow_times,
                         counterlisttype* const num_growths,
                         counterlisttype* const num_augmentations,
                         counterlisttype* const num_adoptions,
                         flowlisttype* const flow_vals,
                         const int num_fg_seed_vars,
                         const bool reuse_trees, const bool rev_lambda)
{
  int lambda_incr = 1;
  int lambda_idx = 0;
  unsigned int in_src_cut = 0;

  if (rev_lambda) {
    lambda_incr = -1;
    in_src_cut = num_vars;
    lambda_idx = num_params - 1;
  }

  const pairwisecaptype* const pairwise_edges_v = pairwise_edges_u + num_pairwise_edges;
  const pairwisecaptype* const pairwise_edges_cap = pairwise_edges_v + num_pairwise_edges;

  Block<GraphType::node_id>* changed_list = new Block<GraphType::node_id>(128);

  tbb::tick_count t0 = tbb::tick_count::now();

  /* construct the lambda_idx = 0 graph */
  GraphType *g = new GraphType(num_vars, num_pairwise_edges);
  g->add_node(num_vars);

  /* add unary capacity edges (t-links) */
  for (GraphType::node_id var_i = 0; var_i < num_vars; ++var_i) {
    unarycaptype s_cap = nonlambda_s[var_i] +
        lambda_range[lambda_idx]*lambda_s[var_i];
    unarycaptype t_cap = nonlambda_t[var_i] +
        lambda_range[num_params-lambda_idx-1]*lambda_t[var_i];

    g->add_tweights(var_i, s_cap, t_cap);
  }

  /* add pairwise capacity edges */
  for (size_t i = 0; i < num_pairwise_edges; ++i) {
    g->add_edge((GraphType::node_id)pairwise_edges_u[i]-1,
                (GraphType::node_id)pairwise_edges_v[i]-1,
                pairwise_edges_cap[i], pairwise_edges_cap[i]);
  }

  double gc_time = (tbb::tick_count::now()-t0).seconds();

  /* run first max-flow */
  t0 = tbb::tick_count::now();
  unarycaptype flow = g->maxflow();
  flow_vals->push_back(flow);
  double mf_time = (tbb::tick_count::now()-t0).seconds();

  /* update the cut result */
  update_cut(g, cuts, lambda_idx, in_src_cut, NULL, rev_lambda);

  /* add timers to the vectors */
  graphconst_times->push_back(gc_time);
  maxflow_times->push_back(mf_time);

  /* add the number of stages BK has to run to the vectors */
  num_growths->push_back(g->get_num_growths());
  num_augmentations->push_back(g->get_num_augmentations());
  num_adoptions->push_back(g->get_num_adoptions());

  /* increment for first iteration */
  lambda_idx += lambda_incr;

  /* reparameterize graphs and compute max-flows for each parameter */
  for (; (!rev_lambda && lambda_idx < num_params && in_src_cut < num_vars) ||
         (rev_lambda && lambda_idx >= 0 && in_src_cut > num_fg_seed_vars);
       lambda_idx += lambda_incr) {
    t0 = tbb::tick_count::now();

    g->update_capacities(num_params, nonlambda_s, nonlambda_t,
                         lambda_s, lambda_t, lambda_range, lambda_idx,
                         lambda_incr);

    gc_time = (tbb::tick_count::now()-t0).seconds();

    /* run max-flow */
    t0 = tbb::tick_count::now();
    /* reuse trees since we have reparameterized the graph */
    if (reuse_trees)
      flow = g->maxflow(true, changed_list);
    else
      flow = g->maxflow();
    flow_vals->push_back(flow);
    mf_time = (tbb::tick_count::now()-t0).seconds();

    /* get the variables which changed to the src side fo the cut */
    if (reuse_trees) {
      update_cut(g, cuts, lambda_idx, in_src_cut, changed_list, rev_lambda);
    } else {
      update_cut(g, cuts, lambda_idx, in_src_cut, NULL, rev_lambda);
    }

    /* add timers to the vectors */
    graphconst_times->push_back(gc_time);
    maxflow_times->push_back(mf_time);

    /* add the number of stages BK has to run to the vectors */
    num_growths->push_back(g->get_num_growths());
    num_augmentations->push_back(g->get_num_augmentations());
    num_adoptions->push_back(g->get_num_adoptions());
  }

  delete g;
  delete changed_list;

  //  std::cout << "\nTimings:\n--------" << std::endl;
  //  std::cout << "Graph construction time: "
  //            << graphconst_time.format(10, "%w") << "s\n";
  //  std::cout << "Max flow time: "
  //            << maxflow_time.format(10, "%w") << "s\n";
}


struct ParallelKohliCutComputation : public ParallelCutComputation {
  const size_t num_graph_types;
  const graphtypeidxtype* const graph_type_start_idx;
  const std::vector<bool>* const reuse_trees;
  const std::vector<bool>* const rev_lambda;
  const std::vector<int>* const fg_seed_nums;

  void operator()(const tbb::blocked_range<int>& range) const {
    GraphType::SrcSeedList seed_remove_list;

    /* compute cuts for each seed using the precomputation graph */
    for (int seed_idx = range.begin(); seed_idx != range.end(); ++seed_idx) {
      /* first identify which graph type this current seed belongs to */
      size_t graph_type_idx = 0;
      for (; graph_type_idx < num_graph_types-1; ++graph_type_idx) {
        graphtypeidxtype end_idx = graph_type_start_idx[graph_type_idx+1]-1;
        if (seed_idx < end_idx)
          break;
      }

      unsigned long offset = seed_idx*num_vars;

      kohli_param_maxflow(num_vars, num_pairwise_edges, num_params,
                          nonlambda_s+offset, nonlambda_t+offset,
                          lambda_s+offset, lambda_t+offset,
                          lambda_range, pairwise_edges, cuts+offset,
                          &((*graphconst_time_all)[seed_idx]),
                          &((*maxflow_time_all)[seed_idx]),
                          &((*growths_all)[seed_idx]),
                          &((*augmentations_all)[seed_idx]),
                          &((*adoptions_all)[seed_idx]),
                          &((*flowvals_all)[seed_idx]),
                          (*fg_seed_nums)[seed_idx],
                          (*reuse_trees)[graph_type_idx],
                          (*rev_lambda)[graph_type_idx]);
    }
  }

  ParallelKohliCutComputation(const size_t& num_vars,
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
                              resulttype* const cuts,
                              std::vector<secslisttype>* const graphconst_time_all,
                              std::vector<secslisttype>* const maxflow_time_all,
                              std::vector<counterlisttype>* const growths_all,
                              std::vector<counterlisttype>* const augmentations_all,
                              std::vector<counterlisttype>* const adoptions_all,
                              std::vector<flowlisttype>* const flowvals_all,
                              std::vector<int>* const fg_seed_nums,
                              const std::vector<bool>* const reuse_trees,
                              const std::vector<bool>* const rev_lambda)
      : ParallelCutComputation(num_vars, num_pairwise_edges, num_params,
                               nonlambda_s, nonlambda_t, lambda_s, lambda_t,
                               lambda_range, pairwise_edges, cuts,
                               graphconst_time_all, maxflow_time_all,
                               growths_all, augmentations_all, adoptions_all,
                               flowvals_all),
        num_graph_types(num_graph_types),
        graph_type_start_idx(graph_type_start_idx), reuse_trees(reuse_trees),
        rev_lambda(rev_lambda), fg_seed_nums(fg_seed_nums) {
  }
};


void kohli_param_maxflow_allseeds(const size_t& num_seeds,
                                  const size_t& num_vars,
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
                                  resulttype* const cuts,
                                  std::vector<metainfotype>* const metainfo,
                                  const std::vector<bool>& reuse_trees,
                                  const std::vector<bool>& rev_lambda,
                                  const bool parallel)
{
  /* print the settings for the max flows we are going to perform */
  std::cout << "kohli BK ||=" << parallel << " ";
  int curr_num_seeds;
  for (size_t i=0; i < num_graph_types; ++i) {
    if (i < num_graph_types-1)
      curr_num_seeds = graph_type_start_idx[i+1] - graph_type_start_idx[i];
    else
      curr_num_seeds = num_seeds - graph_type_start_idx[i] + 1;
    std::cout << " [#seeds=" << curr_num_seeds
              << ", rt=" << reuse_trees[i] << ", rl=" << rev_lambda[i] << "]";
  }

  std::vector<secslisttype> graphconst_time_all(num_seeds, secslisttype());
  std::vector<secslisttype> maxflow_time_all(num_seeds, secslisttype());

  std::vector<counterlisttype> growths_all(num_seeds, counterlisttype());
  std::vector<counterlisttype> augmentations_all(num_seeds, counterlisttype());
  std::vector<counterlisttype> adoptions_all(num_seeds, counterlisttype());

  std::vector<flowlisttype> flowvals_all(num_seeds, flowlisttype());

  std::vector<int> fg_seed_nums;

  gather_seed_nums(num_seeds, num_vars, fg_seed_nums, nonlambda_s, nonlambda_t);

  /* create the class which can do parrallel seed cuts */
  ParallelKohliCutComputation parallelcut(num_vars, num_pairwise_edges,
                                          num_params, num_graph_types,
                                          nonlambda_s, nonlambda_t,
                                          lambda_s, lambda_t, lambda_range,
                                          pairwise_edges, graph_type_start_idx,
                                          cuts, &graphconst_time_all,
                                          &maxflow_time_all, &growths_all,
                                          &augmentations_all, &adoptions_all,
                                          &flowvals_all, &fg_seed_nums,
                                          &reuse_trees, &rev_lambda);

  if (parallel)
    /* compute max-flow/min-cut in parallel */
    tbb::parallel_for(tbb::blocked_range<int>(0, num_seeds), parallelcut);
  else
    /* compute max-flow/min-cut in serial */
    parallelcut(tbb::blocked_range<int>(0, num_seeds));

  /* a meta info row for each info type */
  metainfo->assign(7, metainfotype());

  /* collate results in the output vectors */
  for (int s=0; s < num_seeds; ++s) {
    for (int i=0; i < graphconst_time_all[s].size(); ++i) {
      (*metainfo)[0].push_back(graphconst_time_all[s][i]);
      (*metainfo)[1].push_back(maxflow_time_all[s][i]);
      (*metainfo)[2].push_back(growths_all[s][i]);
      (*metainfo)[3].push_back(augmentations_all[s][i]);
      (*metainfo)[4].push_back(adoptions_all[s][i]);
      (*metainfo)[5].push_back(flowvals_all[s][i]);
      (*metainfo)[6].push_back(s);
    }
  }
}
