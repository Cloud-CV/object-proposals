// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014


#include "tests.h"
#include <boost/format.hpp>
#include <tbb/parallel_for.h>
#include <tbb/blocked_range.h>

void generate_seed_fix_list(GraphType::SrcSeedList* seed_remove_list,
                            const GraphType::FGSeedsType& fg_nodes,
                            const int keep_src_id) {
  seed_remove_list[0].clear();
  seed_remove_list[1].clear();

  for (size_t i = 0; i < fg_nodes.size(); ++i) {
    if (i != keep_src_id) {
      seed_remove_list[0].insert(seed_remove_list[0].end(), fg_nodes[i].begin(),
                                 fg_nodes[i].end());
      seed_remove_list[1].insert(seed_remove_list[1].end(), fg_nodes[i].begin(),
                                 fg_nodes[i].end());
    }
  }
  for (size_t i = 0; i < seed_remove_list[0].size(); ++i) {
    seed_remove_list[0][i].second.second = 0;
    seed_remove_list[1][i].second.first = 0;
  }
}

struct ParallelCutComputation {
  const GraphType* const g_precomp;
  std::vector<GraphType*>* const g_fgs_precomp;
  const GraphType::FGSeedsType* const fg_nodes;
  const unsigned int node_rows;

  void operator()(const tbb::blocked_range<int>& range) const {
    GraphType::SrcSeedList seed_remove_list[2];

    /* compute cuts for each seed using the precomputation graph */
    for (int fg_idx = range.begin(); fg_idx != range.end(); ++fg_idx) {
      // copy the precomputation graph
      GraphType* g_fg_precomp = new GraphType(*g_precomp);
      (*g_fgs_precomp)[fg_idx] = g_fg_precomp;

      // get the fg seeds sans the current seed
      generate_seed_fix_list(seed_remove_list, *fg_nodes, fg_idx);
      // transform all S trees (sans the current seed) to sink
      g_fg_precomp->transform_seed_trees(fg_idx, seed_remove_list);

      g_fg_precomp->check_tree_integrity();

      // generate visualization after the seed tree transformation
      g_fg_precomp->generate_graph_visualization(
          node_rows, ((boost::format("graph1_%d") % (fg_idx + 1)).str()));

      // compute the cut after the precomputation for this seed
      int flow_fg_precomp = run_print_maxflow(g_fg_precomp, *fg_nodes,
                                              node_rows, true);

      // generate visualization after cut computation (and generate final pdf)
      g_fg_precomp->generate_graph_visualization(
          node_rows, ((boost::format("graph2_%d") % (fg_idx + 1)).str()));
      g_fg_precomp->generate_pdf_graphs(
          (boost::format("fg%d_precomp") % (fg_idx + 1)).str());
    }
  }

  ParallelCutComputation(const GraphType* const g_precomp,
                         std::vector<GraphType*>* const g_fgs_precomp,
                         const GraphType::FGSeedsType* const fg_nodes,
                         const unsigned int node_rows)
      : g_precomp(g_precomp),
        g_fgs_precomp(g_fgs_precomp),
        fg_nodes(fg_nodes),
        node_rows(node_rows) {
  }
};

void test_seedsolve() {
  const int NUM_FGS = 3;

  unsigned int node_rows;

  // stores the fg seed graphs and computes cuts from scratch
  std::vector<GraphType*> g_fgs;
  // stores the fg seed graphs and computes graphs from precomputation
  std::vector<GraphType*> g_fgs_precomp(NUM_FGS);

  GraphType::FGSeedsType fg_nodes;

  /* compute cuts for each seed from scratch */
  for (unsigned int fg_idx = 0; fg_idx < NUM_FGS; ++fg_idx) {
    // generate graph with just the fg_idx seed
    int use_seed[NUM_FGS];
    for (int i = 0; i < NUM_FGS; ++i)
      use_seed[i] = 0;
    use_seed[fg_idx] = 1;

    GraphType* g_fg = generate_example4_graph(fg_nodes, node_rows, use_seed);
    g_fgs.push_back(g_fg);

    g_fg->generate_graph_visualization(node_rows,
                       ((boost::format("graph%d_pre") % (fg_idx + 1)).str()));
    // compute max flow and generate visualization
    int flow_fg = run_print_maxflow(g_fg, fg_nodes, node_rows);
    g_fg->generate_graph_visualization(node_rows,
                       ((boost::format("graph%d_post") % (fg_idx + 1)).str()));
    g_fg->generate_pdf_graphs((boost::format("fg%d") % (fg_idx + 1)).str());
  }

  /* generate the precomputation graph using all the fg seeds */
  static const int use_seed_all[] = { -1 };
  GraphType* g_precomp = generate_example4_graph(fg_nodes, node_rows,
                                                 use_seed_all);
  int flow_precomp = run_print_maxflow(g_precomp, fg_nodes, node_rows);
  g_precomp->generate_graph_visualization(node_rows);
  g_precomp->generate_pdf_graphs("precomp");

  // create the class which can do parrallel seed cuts
  ParallelCutComputation parallelcut(g_precomp, &g_fgs_precomp, &fg_nodes,
                                     node_rows);

  // compute max-flow/min-cut in serial
  //parallelcut(tbb::blocked_range<int>(0, fg_nodes.size()));

  // compute max-flow/min-cut in
  tbb::parallel_for(tbb::blocked_range<int>(0, fg_nodes.size()), parallelcut);

  /* compare results (from the standard min-cut, and the multi-seed
   * precomputation) */
  bool test_passed = true;
  for (unsigned int fg_idx = 0; fg_idx < NUM_FGS; ++fg_idx) {
    GraphType* g_fg_precomp = g_fgs_precomp[fg_idx];
    GraphType* g_fg = g_fgs[fg_idx];

    std::cout << "comparing seed result: " << fg_idx << " | nodes: "
              << g_fg_precomp->get_node_num() << std::endl;

    // comparing the pixel by pixel cut solutions
    for (int i = 0; i < g_fg_precomp->get_node_num(); ++i) {
      if (g_fg_precomp->what_segment(i) != g_fg->what_segment(i)) {
        std::cerr << "Inconsistent result for node " << i << " for seed "
                  << fg_idx << std::endl;
        test_passed = false;
      }
    }

    // comparing the flow values of the two graphs
    if (g_fg_precomp->get_flow() != g_fg->get_flow()) {
      std::cerr << "Inconsistent max-flow/min-cut value for seed " << fg_idx
                << " (precomp: " << g_fg_precomp->get_flow() << ", standard: "
                << g_fg->get_flow() << std::endl;
      test_passed = false;
    }
  }

  if (test_passed)
    std::cout << "Graph seed precomputation test PASSED" << std::endl;
  else
    std::cerr << "Graph seed precomputation test FAILED" << std::endl;

  /* memory dealloc */
  for (int i = 0; i < g_fgs.size(); ++i)
    delete g_fgs[i];
  delete g_precomp;
  for (int i = 0; i < g_fgs_precomp.size(); ++i)
    delete g_fgs_precomp[i];
}
