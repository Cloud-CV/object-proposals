// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

GraphType* generate_example5_graph(GraphType::FGSeedsType& fg_nodes,
                                   unsigned int& node_rows,
                                   const int use_seed[], int lambda)
{
  /* capacity edges */
  const int NUM_NODES = 15;
  const int NUM_EDGES = 21;
  int edges_a[]   = {0, 0, 1, 2, 3, 4, 4, 5, 6, 6, 6, 7, 7, 8, 9, 9, 9, 10, 10, 11, 12};
  int edges_b[]   = {3, 4, 4, 4, 6, 6, 8, 8, 7, 9, 10, 8, 10, 10, 10, 12, 13, 11, 14, 14, 13};
  int edges_cap[] = {30, 4, 10, 40, 20, 4, 10, 30, 4, 6, 40, 10, 40, 10, 8, 20, 6, 10, 20, 30, 4};
  int bg_cap[] = {1, 10, 10, 3, 1, 1, 7, 7, 10, 5, 1, 5, 10, 5, 7};



  GraphType::SrcSeedList fg1, fg2;

  static const unsigned int fg_nodes1[] = { 3, 4 };
  create_seed_list(fg_nodes1, sizeof(fg_nodes1)/sizeof(fg_nodes1[0]), fg1);
  static const unsigned int fg_nodes2[] = { 10 };
  create_seed_list(fg_nodes2, sizeof(fg_nodes2)/sizeof(fg_nodes2[0]), fg2);

  fg_nodes.clear();

  if (use_seed[0] == -1 || use_seed[0] == 1)
    fg_nodes.push_back(fg1);
  if (use_seed[0] == -1 || use_seed[1] == 1)
    fg_nodes.push_back(fg2);

  GraphType* g = construct_graph(NUM_NODES, NUM_EDGES, bg_cap, edges_a, edges_b,
                                 edges_cap, fg_nodes, lambda);

  node_rows = 3;

  return g;
}

void example5() {
  unsigned int node_rows;

  GraphType::FGSeedsType fg_nodes;

  static const int use_seed[] = {-1};
  GraphType* g = generate_example5_graph(fg_nodes, node_rows, use_seed);

  run_print_maxflow(g, fg_nodes, node_rows);

  g->generate_graph_visualization(node_rows);
  g->generate_pdf_graphs();

  delete g;
}
