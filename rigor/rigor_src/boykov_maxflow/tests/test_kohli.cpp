// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014


#include "block.h"
#include "tests.h"

GraphType* generate_lambda_graph(int lambda, unsigned int& node_rows,
                                 GraphType::FGSeedsType& fg_nodes) {
  static const int use_seed[] = {0, 0, 1};
  GraphType* g = generate_example4_graph(fg_nodes, node_rows, use_seed, lambda);
  return g;
}

void dynamicgraph_test() {
  unsigned int node_rows;

  GraphType::FGSeedsType fg_nodes, fg_nodes2;
  Block<GraphType::node_id>* changed_list = new Block<GraphType::node_id>(128);

  /* the constant value added to all unaries connected to sink */
  const int LAMBDA = 5;

  GraphType* g1 = generate_lambda_graph(0, node_rows, fg_nodes);
  int flow1 = run_print_maxflow(g1, fg_nodes, node_rows);

  GraphType::SrcSeedNode* it;

  /* iterate and compute max flow while ramping up unaries by 1 in each
   * iteration */
  for (unsigned int l=1; l <= LAMBDA; ++l) {
    /* change graph: add 1 unary weight to each bg node */
    for (unsigned int i = 0; i < g1->get_node_num(); ++i) {
      int fg_node_id = get_node_source_id(i, fg_nodes, it);

      /* if the node is just connected to sink */
      if (fg_node_id == INVALID_SRC_ID) {
        g1->add_tweights(i, 0, 1);
        g1->mark_node(i);
      }
    }

    /* run max flow again */
    flow1 = run_print_maxflow(g1, fg_nodes, node_rows, true, changed_list);

    g1->print_changed_list();

    /* reset the list of changed nodes */
    GraphType::node_id* ptr;
    for (ptr=changed_list->ScanFirst(); ptr; ptr=changed_list->ScanNext()) {
      GraphType::node_id i = *ptr;
      g1->remove_from_changed_list(i);
    }
    changed_list->Reset();

    std::cout << "-------------------------------------------------------" <<
                 std::endl;
  }

  /* generate a graph where LAMBDA has already been added to the unary
   * capacities */
  GraphType* g2 = generate_lambda_graph(LAMBDA, node_rows, fg_nodes2);
  int flow2 = run_print_maxflow(g2, fg_nodes2, node_rows);

  /* check if the solutions are the same */
  bool all_sols_same = true;
  for (int i = 0; i < g1->get_node_num(); ++i) {
    if (g1->what_segment(i) != g2->what_segment(i)) {
      /* print any inconsistencies */
      std::cerr << "Solution at node " << i << " not the same" << std::endl;
      all_sols_same = false;
    }
  }
  std::cout << std::endl;
  if (all_sols_same && flow1 == flow2)
    std::cout << "DYNAMIC GRAPH TEST PASSED!" << std::endl;
  else
    std::cerr << "DYNAMIC GRAPH TEST FAILED!" << std::endl;

  delete g1, g2;
  delete changed_list;
}
