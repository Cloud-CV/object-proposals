// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#ifndef _BK_DYNAMICGRAPHS_H_
#define _BK_DYNAMICGRAPHS_H_

#include "mex.h"

#include <iostream>
#include <map>
#include <boost/format.hpp>
#include <boost/algorithm/string.hpp>
#include <tbb/tick_count.h>
#include <tbb/parallel_for.h>
#include <tbb/blocked_range.h>

#include "../graph.h"

typedef double unarycaptype;
typedef double pairwisecaptype;
typedef double lambdaparamtype;
typedef double graphtypeidxtype;
typedef unsigned short resulttype;

typedef double metainfosingletype;
typedef std::vector<double> metainfotype;
typedef std::vector<double> secslisttype;
typedef std::vector<unsigned int> counterlisttype;
typedef std::vector<unarycaptype> flowlisttype;

typedef Graph<pairwisecaptype, unarycaptype, unarycaptype> GraphType;

typedef std::pair<int, int> fgseedmapvaltype;
typedef std::map<GraphType::node_id, fgseedmapvaltype> fgseedmaptype;

const double INF_SEED_THRESH = 21475000000;

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
                                const bool rev_lambda=false);

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
                                         const std::vector<bool>& opp_lambda,
                                         const bool parallel=true);

void kohli_param_maxflow(const size_t& num_vars,
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
                         flowlisttype* const flow_vals,
                         const int num_fg_seed_vars,
                         const bool reuse_trees=true,
                         const bool rev_lambda=false);

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
                                  const bool parallel=true);

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
                             flowlisttype* const flow_vals);

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
                                      const bool parallel=true);

void update_cut(GraphType* const g, resulttype* const cuts,
                const unsigned int lambda_idx, unsigned int& in_src_cut,
                Block<GraphType::node_id>* const changed_list=NULL,
                const bool REV=false);

void gather_seed_nums(const size_t& num_seeds, const size_t& num_vars,
                      std::vector<int>& fg_seed_nums,
                      const unarycaptype* const nonlambda_s,
                      const unarycaptype* const nonlambda_t);

void gather_seed_vars(const size_t& num_seeds, const size_t& num_vars,
                      GraphType::FGSeedsType* const fg_seeds,
                      fgseedmaptype* const fg_seed_map,
                      const unarycaptype* const nonlambda_s,
                      const unarycaptype* const nonlambda_t);

struct ParallelCutComputation {
  const size_t num_vars, num_pairwise_edges, num_params;
  const unarycaptype* const nonlambda_s;
  const unarycaptype* const nonlambda_t;
  const unarycaptype* const lambda_s;
  const unarycaptype* const lambda_t;
  const lambdaparamtype* const lambda_range;
  const pairwisecaptype* const pairwise_edges;

  resulttype* const cuts;

  std::vector<secslisttype>* const graphconst_time_all;
  std::vector<secslisttype>* const maxflow_time_all;

  std::vector<counterlisttype>* const growths_all;
  std::vector<counterlisttype>* const augmentations_all;
  std::vector<counterlisttype>* const adoptions_all;

  std::vector<flowlisttype>* const flowvals_all;

  // The operator for doing the parallelization
  virtual void operator()(const tbb::blocked_range<int>& range) const = 0;

  ParallelCutComputation(const size_t& num_vars,
                         const size_t& num_pairwise_edges,
                         const size_t& num_params,
                         const unarycaptype* const nonlambda_s,
                         const unarycaptype* const nonlambda_t,
                         const unarycaptype* const lambda_s,
                         const unarycaptype* const lambda_t,
                         const lambdaparamtype* const lambda_range,
                         const pairwisecaptype* const pairwise_edges,
                         resulttype* cuts,
                         std::vector<secslisttype>* graphconst_time_all,
                         std::vector<secslisttype>* maxflow_time_all,
                         std::vector<counterlisttype>* growths_all,
                         std::vector<counterlisttype>* augmentations_all,
                         std::vector<counterlisttype>* adoptions_all,
                         std::vector<flowlisttype>* flowvals_all)
      : num_vars(num_vars), num_pairwise_edges(num_pairwise_edges),
        num_params(num_params), nonlambda_s(nonlambda_s),
        nonlambda_t(nonlambda_t), lambda_s(lambda_s), lambda_t(lambda_t),
        lambda_range(lambda_range), pairwise_edges(pairwise_edges),
        cuts(cuts), graphconst_time_all(graphconst_time_all),
        maxflow_time_all(maxflow_time_all), growths_all(growths_all),
        augmentations_all(augmentations_all), adoptions_all(adoptions_all),
        flowvals_all(flowvals_all) {
  }

  virtual ~ParallelCutComputation() {}
};

#endif // _BK_DYNAMICGRAPHS_H_
