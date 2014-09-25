// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "bk_dynamicgraphs.h"


void nodynamic_param_maxflow(const size_t& num_vars,
                             const size_t& num_pairwise_edges,
                             const size_t& num_params,
                             const unarycaptype* const nonlambda_s,
                             const unarycaptype* const nonlambda_t,
                             const unarycaptype* const lambda_s,
                             const unarycaptype* const lambda_t,
                             const lambdaparamtype* const lambda_range,
                             const pairwisecaptype* const pairwise_edges,
                             resulttype* const cuts,
                             secslisttype* const graphconst_times,
                             secslisttype* const maxflow_times,
                             counterlisttype* const num_growths,
                             counterlisttype* const num_augmentations,
                             counterlisttype* const num_adoptions,
                             flowlisttype* const flow_vals)
{
  const int lambda_idx = 0;

  const pairwisecaptype* const pairwise_edges_v = pairwise_edges + num_pairwise_edges;
  const pairwisecaptype* const pairwise_edges_cap = pairwise_edges_v + num_pairwise_edges;

  bool all_src = false;

  tbb::tick_count t0;

  for (unsigned int lambda_idx=0; lambda_idx < num_params && !all_src;
       ++lambda_idx) {
    t0 = tbb::tick_count::now();
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
      g->add_edge((GraphType::node_id)pairwise_edges[i]-1,
                  (GraphType::node_id)pairwise_edges_v[i]-1,
                  pairwise_edges_cap[i], pairwise_edges_cap[i]);
    }
    double gc_time = (tbb::tick_count::now()-t0).seconds();

    /* run max-flow */
    t0 = tbb::tick_count::now();
    unarycaptype flow = g->maxflow();
    //std::cout << flow << std::endl;
    flow_vals->push_back(flow);
    double mf_time = (tbb::tick_count::now()-t0).seconds();

    all_src = true;

    /* get the variables which changed to the src side fo the cut */
    for (GraphType::node_id var_i = 0; var_i < num_vars; ++var_i) {
      if (cuts[var_i] == 0) {
        if (g->what_segment(var_i) == GraphType::SOURCE) {
          cuts[var_i] = lambda_idx+1;
        } else {
          all_src = false;
        }
      }
    }

    /* add timers to the vectors */
    graphconst_times->push_back(gc_time);
    maxflow_times->push_back(mf_time);

    /* add the number of stages BK has to run to the vectors */
    num_growths->push_back(g->get_num_growths());
    num_augmentations->push_back(g->get_num_augmentations());
    num_adoptions->push_back(g->get_num_adoptions());

    delete g;
  }

  //  std::cout << "\nTimings:\n--------" << std::endl;
  //  std::cout << "Graph construction time: "
  //            << graphconst_time.format(10, "%w") << "s\n";
  //  std::cout << "Max flow time: "
  //            << maxflow_time.format(10, "%w") << "s\n";
}


struct ParallelNoDynamicCutComputation : public ParallelCutComputation {
  void operator()(const tbb::blocked_range<int>& range) const {
    GraphType::SrcSeedList seed_remove_list;

    /* compute cuts for each seed using the precomputation graph */
    for (int seed_idx = range.begin(); seed_idx != range.end(); ++seed_idx) {
      unsigned long offsets = seed_idx*num_vars;
      nodynamic_param_maxflow(num_vars, num_pairwise_edges, num_params,
                              nonlambda_s+offsets, nonlambda_t+offsets,
                              lambda_s+offsets, lambda_t+offsets,
                              lambda_range, pairwise_edges, cuts+offsets,
                              &((*graphconst_time_all)[seed_idx]),
                              &((*maxflow_time_all)[seed_idx]),
                              &((*growths_all)[seed_idx]),
                              &((*augmentations_all)[seed_idx]),
                              &((*adoptions_all)[seed_idx]),
                              &((*flowvals_all)[seed_idx]));
    }
  }

  ParallelNoDynamicCutComputation(const size_t& num_vars,
                                  const size_t& num_pairwise_edges,
                                  const size_t& num_params,
                                  const unarycaptype* const nonlambda_s,
                                  const unarycaptype* const nonlambda_t,
                                  const unarycaptype* const lambda_s,
                                  const unarycaptype* const lambda_t,
                                  const lambdaparamtype* const lambda_range,
                                  const pairwisecaptype* const pairwise_edges,
                                  resulttype* const cuts,
                                  std::vector<secslisttype>* const graphconst_time_all,
                                  std::vector<secslisttype>* const maxflow_time_all,
                                  std::vector<counterlisttype>* const growths_all,
                                  std::vector<counterlisttype>* const augmentations_all,
                                  std::vector<counterlisttype>* const adoptions_all,
                                  std::vector<flowlisttype>* const flowvals_all)
      : ParallelCutComputation(num_vars, num_pairwise_edges, num_params,
                               nonlambda_s, nonlambda_t, lambda_s, lambda_t,
                               lambda_range, pairwise_edges, cuts,
                               graphconst_time_all, maxflow_time_all,
                               growths_all, augmentations_all, adoptions_all,
                               flowvals_all) {
  }
};


void nodynamic_param_maxflow_allseeds(const size_t& num_seeds,
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
                                      const bool parallel)
{
  /* print the settings for the max flows we are going to perform */
  std::cout << "nodynamic BK ||=" << parallel << ", #seeds=" << num_seeds;

  std::vector<secslisttype> graphconst_time_all(num_seeds, secslisttype());
  std::vector<secslisttype> maxflow_time_all(num_seeds, secslisttype());

  std::vector<counterlisttype> growths_all(num_seeds, counterlisttype());
  std::vector<counterlisttype> augmentations_all(num_seeds, counterlisttype());
  std::vector<counterlisttype> adoptions_all(num_seeds, counterlisttype());

  std::vector<flowlisttype> flowvals_all(num_seeds, flowlisttype());

  /* create the class which can do parrallel seed cuts */
  ParallelNoDynamicCutComputation parallelcut(num_vars, num_pairwise_edges,
                                              num_params, nonlambda_s,
                                              nonlambda_t, lambda_s, lambda_t,
                                              lambda_range, pairwise_edges,
                                              cuts, &graphconst_time_all,
                                              &maxflow_time_all, &growths_all,
                                              &augmentations_all,
                                              &adoptions_all, &flowvals_all);

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
