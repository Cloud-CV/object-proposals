// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

void example2() {
  const int NODE_ROWS = 3;

  GraphType *g = new GraphType(15, 1);

  const int lambda = 3;
  const int fg_node = 4;

  g->add_node(15);
  for (unsigned int i = 0; i < 15; ++i) {
    if (i == fg_node)
      g->add_tweights(i, /* capacities */infty, 0);
    else
      g->add_tweights(i, /* capacities */0, lambda);
  }

  /* capacity edges */
  g->add_edge(0, 3, /* capacities */80, 80);
  g->add_edge(0, 4, /* capacities */2, 2);

  g->add_edge(1, 2, /* capacities */20, 20);

  g->add_edge(2, 5, /* capacities */30, 30);

  g->add_edge(3, 4, /* capacities */2, 2);
  g->add_edge(3, 6, /* capacities */80, 80);

  g->add_edge(4, 5, /* capacities */25, 25);
  g->add_edge(4, 7, /* capacities */2, 2);
  g->add_edge(4, 8, /* capacities */30, 30);

  g->add_edge(6, 9, /* capacities */80, 80);

  //g -> add_edge( 7, 8,    /* capacities */  2, 2 );
  g->add_edge(7, 9, /* capacities */2, 2);
  //g -> add_edge( 7,10,    /* capacities */  2, 2 );

  g->add_edge(8, 10, /* capacities */40, 40);

  g->add_edge(9, 10, /* capacities */2, 2);
  g->add_edge(9, 12, /* capacities */80, 80);

  g->add_edge(10, 11, /* capacities */1, 1);
  g->add_edge(10, 13, /* capacities */40, 40);
  g->add_edge(10, 14, /* capacities */3, 3);

  g->add_edge(11, 14, /* capacities */2, 2);

  g->add_edge(12, 13, /* capacities */2, 2);

  int flow = g->maxflow();

  g->generate_graph_visualization(NODE_ROWS);
  g->generate_pdf_graphs();


  std::cout << "Flow = " << flow << std::endl;
  std::cout << "Minimum cut:" << std::endl;
  for (int j = 0; j < NODE_ROWS; ++j) {
    for (int i = j; i < g->get_node_num(); i += NODE_ROWS) {
      if (g->what_segment(i) == GraphType::SOURCE)
        std::cout << "\tS";
      else
        std::cout << "\tT";
    }
    std::cout << std::endl;
  }

  delete g;
}
