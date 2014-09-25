// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014


#include "examples.h"

void example1() {
  typedef Graph<int, int, int> GraphType;
  GraphType *g = new GraphType(/*estimated # of nodes*/2, /*estimated # of edges*/
                               1);

  g->add_node();
  g->add_node();

  g->add_tweights(0, /* capacities */3, 9);
  g->add_tweights(1, /* capacities */8, 1);
  g->add_edge(0, 1, /* capacities */3, 4);

  int flow = g->maxflow();

  std::cout << "Flow = " << flow << std::endl;
  std::cout << "Minimum cut:" << std::endl;
  for (int i = 0; i < g->get_node_num(); ++i) {
    if (g->what_segment(i) == GraphType::SOURCE)
      std::cout << "node " << i << " is in the SOURCE set" << std::endl;
    else
      std::cout << "node " << i << " is in the SINK set" << std::endl;
  }

  delete g;
}
