// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

GraphType* generate_example3_graph(GraphType::FGSeedsType& fg_nodes,
                                   unsigned int& node_rows,
                                   const int use_seed[], int lambda)
{
  const int NUM_NODES = 15;
  int bg_cap[] = {2, 2, 2, 14, 1, 2, 1, 10, 4, 10, 1, 7, 20, 4, 20};

  /* capacity edges */
  const int NUM_EDGES = 23;
  int edges_a[]   = {0, 1, 1, 2, 2, 3, 4, 4, 4, 5, 5, 6, 6,  6, 7,  7,  8, 10, 10, 10, 11, 12, 13};
  int edges_b[]   = {1, 2, 3, 4, 5, 6, 5, 6, 7, 7, 8, 7, 9, 10, 8, 10, 10, 11, 12, 14, 14, 13, 14};
  int edges_cap[] = {5, 7, 8, 5, 6, 6, 6, 9, 5, 4, 5, 9, 5,  4, 7, 20, 20,  8,  4, 20,  6, 10,  5};

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

void example3() {
  unsigned int node_rows;

  GraphType::FGSeedsType fg_nodes;

  static const int use_seed[] = {-1};
  GraphType* g = generate_example3_graph(fg_nodes, node_rows, use_seed);

  run_print_maxflow(g, fg_nodes, node_rows);

  g->generate_graph_visualization(node_rows);
  g->generate_pdf_graphs();

  delete g;
}
