// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014


#include "tests.h"

void test_deepcopy()
{
  unsigned int node_rows;

  GraphType::FGSeedsType fg_nodes;

  Block<GraphType::node_id>* changed_list = new Block<GraphType::node_id>(128);

  static const int use_seed[] = {1, 0, 1};
  GraphType* g_orig = generate_example4_graph(fg_nodes, node_rows, use_seed);

  GraphType* g_cpy = new GraphType(*g_orig);
  GraphType* g_cpy2 = new GraphType(*g_cpy);

  int flow_orig = run_print_maxflow(g_orig, fg_nodes, node_rows);
  g_orig->generate_graph_visualization(node_rows);
  g_orig->generate_pdf_graphs("orig");

  delete g_orig;

  int flow_cpy1 = run_print_maxflow(g_cpy, fg_nodes, node_rows, true, changed_list);
  g_cpy->generate_graph_visualization(node_rows);
  g_cpy->generate_pdf_graphs("cpy");

  int flow_cpy2 = run_print_maxflow(g_cpy2, fg_nodes, node_rows);
  g_cpy2->generate_graph_visualization(node_rows);
  g_cpy2->generate_pdf_graphs("cpy2");

  delete g_cpy;
  delete g_cpy2;

  delete changed_list;
}
