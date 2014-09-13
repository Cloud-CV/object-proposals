// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

GraphType* generate_example4_graph(GraphType::FGSeedsType& fg_nodes,
                                   unsigned int& node_rows,
                                   const int use_seed[], int lambda)
{
  const int NUM_NODES = 64;
  int bg_cap[] = {3, 7, 7, 3, 1, 10, 5, 1, 5, 10, 7, 5, 10, 5, 5, 7, 1, 10, 1, 7, 7, 3, 10, 1, 1, 10, 5, 5, 5, 7, 10, 1, 3, 10, 5, 10, 7, 3, 3, 7, 5, 1, 5, 5, 10, 3, 1, 5, 1, 1, 1, 3, 7, 1, 7, 1, 3, 3, 7, 1, 10, 10, 1, 5};

  /* capacity edges */
  const int NUM_EDGES = 115;
  int edges_a[]   = {0, 0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 5, 6, 7, 8, 8, 9, 10, 10, 11, 11, 12, 12, 12, 14, 14, 15, 16, 17, 17, 17, 17, 18, 19, 19, 19, 20, 20, 21, 21, 21, 22, 22, 22, 24, 24, 25, 25, 26, 26, 26, 27, 27, 28, 28, 29, 29, 29, 30, 31, 31, 32, 33, 33, 33, 34, 34, 35, 35, 35, 36, 37, 37, 37, 38, 38, 38, 38, 39, 40, 40, 41, 42, 42, 42, 43, 43, 44, 44, 44, 45, 45, 46, 46, 46, 47, 48, 49, 49, 49, 50, 51, 51, 51, 52, 52, 52, 53, 53, 53, 54, 59, 60, 61};
  int edges_b[]   = {1, 8, 8, 9, 10, 10, 11, 11, 12, 13, 6, 13, 14, 14, 14, 9, 17, 18, 18, 19, 12, 20, 13, 20, 21, 21, 23, 23, 17, 18, 24, 25, 26, 26, 26, 27, 28, 21, 29, 22, 29, 30, 23, 30, 31, 32, 33, 26, 34, 27, 34, 35, 35, 36, 29, 36, 30, 36, 38, 38, 38, 39, 33, 34, 40, 41, 42, 43, 36, 43, 44, 37, 38, 44, 45, 39, 45, 46, 47, 47, 41, 49, 49, 43, 49, 51, 44, 51, 51, 52, 53, 46, 53, 47, 54, 55, 55, 56, 56, 57, 58, 59, 52, 59, 60, 53, 60, 61, 54, 61, 62, 63, 60, 61, 62};
  int edges_cap[] = {10, 4, 8, 8, 4, 10, 40, 40, 8, 6, 4, 40, 10, 40, 20, 30, 8, 30, 40, 4, 8, 10, 6, 4, 40, 40, 40, 8, 40, 6, 40, 4, 6, 4, 8, 6, 10, 4, 30, 10, 40, 30, 8, 4, 8, 40, 30, 20, 10, 10, 10, 10, 40, 8, 6, 10, 6, 40, 40, 40, 4, 10, 40, 40, 10, 4, 4, 20, 30, 10, 4, 20, 40, 8, 8, 6, 4, 4, 10, 6, 10, 40, 20, 6, 40, 40, 20, 40, 30, 6, 30, 30, 10, 8, 8, 20, 4, 8, 8, 30, 10, 4, 4, 8, 10, 8, 10, 6, 6, 40, 8, 8, 20, 40, 10};

  GraphType::SrcSeedList fg1, fg2, fg3;

  static const unsigned int fg_nodes1[] = { 10, 11 };
  create_seed_list(fg_nodes1, sizeof(fg_nodes1)/sizeof(fg_nodes1[0]), fg1);
  static const unsigned int fg_nodes2[] = { 42 };
  create_seed_list(fg_nodes2, sizeof(fg_nodes2)/sizeof(fg_nodes2[0]), fg2);
  static const unsigned int fg_nodes3[] = { 29, 37, 38 };
  create_seed_list(fg_nodes3, sizeof(fg_nodes3)/sizeof(fg_nodes3[0]), fg3);

  fg_nodes.clear();

  if (use_seed[0] == -1 || use_seed[0] == 1)
    fg_nodes.push_back(fg1);
  if (use_seed[0] == -1 || use_seed[1] == 1)
    fg_nodes.push_back(fg2);
  if (use_seed[0] == -1 || use_seed[2] == 1)
    fg_nodes.push_back(fg3);

  GraphType* g = construct_graph(NUM_NODES, NUM_EDGES, bg_cap, edges_a, edges_b,
                                 edges_cap, fg_nodes, lambda);

  node_rows = 8;

  return g;
}

void example4() {
  unsigned int node_rows;

  GraphType::FGSeedsType fg_nodes;

  static const int use_seed[] = {-1};
  GraphType* g = generate_example4_graph(fg_nodes, node_rows, use_seed);

  run_print_maxflow(g, fg_nodes, node_rows);

  g->generate_graph_visualization(node_rows);
  g->generate_pdf_graphs();

  delete g;
}
