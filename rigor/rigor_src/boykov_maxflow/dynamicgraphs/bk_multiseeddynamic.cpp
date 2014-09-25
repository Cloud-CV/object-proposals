// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "bk_multiseeddynamic.h"

void multiseeddyn_param_maxflow(const size_t& num_vars,
                                const size_t& num_pairwise_edges,
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
                                const pairwisecaptype* const pairwise_edges_u,
                                resulttype* const cuts,
                                secslisttype* const graphconst_times,
                                secslisttype* const maxflow_times,
                                counterlisttype* const num_growths,
                                counterlisttype* const num_augmentations,
                                counterlisttype* const num_adoptions,
                                flowlisttype* const flow_vals,
                                const GraphType* const g_precomp,
                                const GraphType::FGSeedsType* const fg_seeds,
                                const fgseedmaptype* const fg_seed_map,
                                const int seed_idx,
                                const unsigned int precomp_lambda_idx,
                                const bool rev_lambda)
{
  const unsigned int num_fg_seed_vars = (*fg_seeds)[seed_idx].size();
  int lambda_incr = 1;
  int lambda_idx = 0;
  unsigned int in_src_cut = 0;
  GraphType* g;

  /* if lambda needs to be scheduled in the reverse direction */
  if (rev_lambda) {
    lambda_incr = -1;
    in_src_cut = num_vars;
    lambda_idx = num_params - 1;
  }

  unarycaptype flow, old_residual_cap, new_residual_cap;

  const pairwisecaptype* const pairwise_edges_v = pairwise_edges_u + num_pairwise_edges;
  const pairwisecaptype* const pairwise_edges_cap = pairwise_edges_v + num_pairwise_edges;

  Block<GraphType::node_id>* changed_list = new Block<GraphType::node_id>(128);

  tbb::tick_count t0;
  double gc_time, mf_time;


  bool first_iter = true;

  // reparameterize graphs and compute max-flows for each parameter -
  // keep running the loop if still more lambdas to schedule and:
  // forward lambda scheduling: if the source cut does not cover all the
  //                            pixels
  // backward lambda scheduling: if the source cut is bigger than
  //                             the number of seeds
  for (; (!rev_lambda && lambda_idx < num_params && in_src_cut < num_vars) ||
         (rev_lambda && lambda_idx >= 0 && in_src_cut > num_fg_seed_vars);
       lambda_idx += lambda_incr) {
    t0 = tbb::tick_count::now();

    if (first_iter) {
      tbb::tick_count graphinit_time = tbb::tick_count::now();
      tbb::tick_count cpy_time = tbb::tick_count::now();

      // copy the precomputation graph
      g = new GraphType(*g_precomp);

      //std::cout << "cpy_time: " << (tbb::tick_count::now()-cpy_time).seconds() << std::endl;

      // if first iteration, then we need to change the precomputation graph
      GraphType::SrcSeedList seed_remove_list[2];

      // convert precomputation graph into an actual graph for this seed
      // get the fg seeds sans the current seed
      update_graph_gen_fg_remove_list(g, seed_remove_list, *fg_seeds, *fg_seed_map,
                                      num_vars, num_params, nonlambda_s,
                                      nonlambda_t, orig_nonlambda_s,
                                      orig_nonlambda_t, lambda_s,
                                      lambda_t, orig_lambda_s, orig_lambda_t,
                                      lambda_range, cuts, in_src_cut,
                                      precomp_lambda_idx, lambda_idx, seed_idx);

      // transform all S trees (sans the current seed) to sink
      g->transform_seed_trees(seed_idx, seed_remove_list);

      //std::cout << "graphinit_time: " << (tbb::tick_count::now()-graphinit_time).seconds() << std::endl;
    } else {
      g->update_capacities(num_params, nonlambda_s, nonlambda_t,
                           lambda_s, lambda_t, lambda_range, lambda_idx,
                           lambda_incr);
    }

    gc_time = (tbb::tick_count::now()-t0).seconds();

    // run max-flow
    t0 = tbb::tick_count::now();
    flow = g->maxflow(true, changed_list, false);
    flow_vals->push_back(flow);
    mf_time = (tbb::tick_count::now()-t0).seconds();

    /*
    unarycaptype flow2 = g->maxflow(false);
    if (flow2 != flow)
      std::cout << "Flow inconsistent" << std::endl;
     */

    // in the first iteration scan the whole set of variables and set the cut
    // and the number variables in the cut. Its more complex to set this before
    // the first iteration and then use the changed_list even in the first
    // iteration, but its possible
    if (first_iter) {
      update_cut(g, cuts, lambda_idx, in_src_cut, NULL, rev_lambda);
    } else {
      update_cut(g, cuts, lambda_idx, in_src_cut, changed_list, rev_lambda);
    }

    /* add timers to the vectors */
    graphconst_times->push_back(gc_time);
    maxflow_times->push_back(mf_time);

    /* add the number of stages BK has to run to the vectors */
    num_growths->push_back(g->get_num_growths());
    num_augmentations->push_back(g->get_num_augmentations());
    num_adoptions->push_back(g->get_num_adoptions());

    first_iter = false;
  }

  delete g;
  delete changed_list;
}


struct ParallelMultiSeedDynCutComputation : public ParallelCutComputation {
  const size_t num_graph_types;
  const graphtypeidxtype* const graph_type_start_idx;
  const std::vector<GraphType*>* const gs_precomp;
  const std::vector<GraphType::FGSeedsType>* const fg_seeds;
  const std::vector<fgseedmaptype>* const fg_seed_map;
  const std::vector<int>* const precomp_lambda_idx;
  const std::vector<bool>* const rev_lambda;

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

      unsigned long base_offset_idx = (graph_type_start_idx[graph_type_idx]-1);
      unsigned long base_offset = base_offset_idx*num_vars;
      unsigned long offset = seed_idx*num_vars;

      const GraphType::FGSeedsType* const curr_type_seeds = &((*fg_seeds)[graph_type_idx]);
      const fgseedmaptype* const curr_type_seed_map = &((*fg_seed_map)[graph_type_idx]);

      multiseeddyn_param_maxflow(num_vars, num_pairwise_edges, num_params,
                                 nonlambda_s+offset, nonlambda_t+offset,
                                 nonlambda_s+base_offset,
                                 nonlambda_t+base_offset, lambda_s+offset,
                                 lambda_t+offset, lambda_s+base_offset,
                                 lambda_t+base_offset, lambda_range,
                                 pairwise_edges, cuts+offset,
                                 &((*graphconst_time_all)[seed_idx]),
                                 &((*maxflow_time_all)[seed_idx]),
                                 &((*growths_all)[seed_idx]),
                                 &((*augmentations_all)[seed_idx]),
                                 &((*adoptions_all)[seed_idx]),
                                 &((*flowvals_all)[seed_idx]),
                                 (*gs_precomp)[graph_type_idx],
                                 curr_type_seeds, curr_type_seed_map,
                                 seed_idx - base_offset_idx,
                                 (*precomp_lambda_idx)[graph_type_idx],
                                 (*rev_lambda)[graph_type_idx]);
    }
  }

  ParallelMultiSeedDynCutComputation(const size_t& num_vars,
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
                                     resulttype* cuts,
                                     std::vector<secslisttype>* graphconst_time_all,
                                     std::vector<secslisttype>* maxflow_time_all,
                                     std::vector<counterlisttype>* growths_all,
                                     std::vector<counterlisttype>* augmentations_all,
                                     std::vector<counterlisttype>* adoptions_all,
                                     std::vector<flowlisttype>* flowvals_all,
                                     const std::vector<GraphType*>* const gs_precomp,
                                     const std::vector<GraphType::FGSeedsType>* const fg_seeds,
                                     const std::vector<fgseedmaptype>* const fg_seed_map,
                                     const std::vector<int>* const precomp_lambda_idx,
                                     const std::vector<bool>* const rev_lambda)
      : ParallelCutComputation(num_vars, num_pairwise_edges, num_params,
                               nonlambda_s, nonlambda_t, lambda_s, lambda_t,
                               lambda_range, pairwise_edges, cuts,
                               graphconst_time_all, maxflow_time_all,
                               growths_all, augmentations_all, adoptions_all,
                               flowvals_all),
        num_graph_types(num_graph_types),
        graph_type_start_idx(graph_type_start_idx), gs_precomp(gs_precomp),
        fg_seeds(fg_seeds), fg_seed_map(fg_seed_map),
        precomp_lambda_idx(precomp_lambda_idx), rev_lambda(rev_lambda) {
  }
};


void multiseeddyn_param_maxflow_allseeds(const size_t& num_seeds,
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
                                         const std::vector<bool>& rev_lambda,
                                         const std::vector<bool>& opp_precomp_lambda,
                                         const bool parallel)
{
  /* print the settings for the max flows we are going to perform */
  std::cout << "multiseed BK ||=" << parallel << " ";
  int curr_num_seeds;
  for (size_t i=0; i < num_graph_types; ++i) {
    if (i < num_graph_types-1)
      curr_num_seeds = graph_type_start_idx[i+1] - graph_type_start_idx[i];
    else
      curr_num_seeds = num_seeds - graph_type_start_idx[i] + 1;
    std::cout << " [#seeds=" << curr_num_seeds
              << ", rl=" << rev_lambda[i]
              << ", opl=" << opp_precomp_lambda[i] << "]";
  }

  std::vector<secslisttype> graphconst_time_all(num_seeds, secslisttype());
  std::vector<secslisttype> maxflow_time_all(num_seeds, secslisttype());

  std::vector<counterlisttype> growths_all(num_seeds, counterlisttype());
  std::vector<counterlisttype> augmentations_all(num_seeds, counterlisttype());
  std::vector<counterlisttype> adoptions_all(num_seeds, counterlisttype());

  std::vector<flowlisttype> flowvals_all(num_seeds, flowlisttype());

  /* set the lambda idx for each graph type from which the precomputation graph
   * is built */
  std::vector<int> precomp_lambda_idx(num_graph_types, 0);
  for (size_t i=0; i < num_graph_types; ++i) {
    /* if the precomputation graph needs to be built from the last lambda
     *  rev_lambda=0, opp_precomp_lambda=0  =>  0
     *  rev_lambda=1, opp_precomp_lambda=0  =>  NP-1
     *  rev_lambda=0, opp_precomp_lambda=1  =>  NP-1
     *  rev_lambda=1, opp_precomp_lambda=1  =>  0 */
    if (rev_lambda[i] ^ opp_precomp_lambda[i]) {
      precomp_lambda_idx[i] = num_params-1;
    }
  }

  std::vector<GraphType::FGSeedsType> fg_seeds(num_graph_types,
                                               GraphType::FGSeedsType());
  std::vector<fgseedmaptype> fg_seed_map(num_graph_types, fgseedmaptype());
  std::vector<GraphType*> gs_precomp(num_graph_types, NULL);

  /* create the precomputation graph in parallel */
  tbb::tick_count t0 = tbb::tick_count::now();
  ParallelMultiseedDynInit parallelinit(num_seeds, num_vars,
                                        num_pairwise_edges, num_params,
                                        num_graph_types, nonlambda_s,
                                        nonlambda_t, lambda_s, lambda_t,
                                        lambda_range, pairwise_edges,
                                        graph_type_start_idx, &precomp_lambda_idx,
                                        &fg_seeds, &fg_seed_map, &gs_precomp);

  if (parallel)
    /* compute max-flow/min-cut in parallel */
    tbb::parallel_for(tbb::blocked_range<size_t>(0, num_graph_types), parallelinit);
  else
    /* compute max-flow/min-cut in serial */
    parallelinit(tbb::blocked_range<size_t>(0, num_graph_types));

  double precomp_time = (tbb::tick_count::now()-t0).seconds();
  //std::cout << "precomp_time: " << precomp_time << std::endl;

  /* create the class which can do parrallel seed cuts */
  ParallelMultiSeedDynCutComputation parallelcut(num_vars, num_pairwise_edges,
                                                 num_params, num_graph_types,
                                                 nonlambda_s, nonlambda_t,
                                                 lambda_s, lambda_t,
                                                 lambda_range, pairwise_edges,
                                                 graph_type_start_idx, cuts,
                                                 &graphconst_time_all,
                                                 &maxflow_time_all, &growths_all,
                                                 &augmentations_all,
                                                 &adoptions_all, &flowvals_all,
                                                 &gs_precomp, &fg_seeds,
                                                 &fg_seed_map, &precomp_lambda_idx,
                                                 &rev_lambda);

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

  /* delete precomputation graphs */
  for (size_t i=0; i < gs_precomp.size(); ++i)
    delete gs_precomp[i];
}
