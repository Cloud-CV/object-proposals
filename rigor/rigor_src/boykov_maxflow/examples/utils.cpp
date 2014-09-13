// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

void create_seed_list(const unsigned int fg_nodes[], const unsigned int NUM_ELEMS,
                      GraphType::SrcSeedList& seed_list)
{
  seed_list.clear();

  for (int i=0; i < NUM_ELEMS; ++i) {
    seed_list.push_back(GraphType::SrcSeedNode(fg_nodes[i], GraphType::NodeCap()));
  }
}

GraphType* construct_graph(const int NUM_NODES, const int NUM_EDGES,
                           const int bg_cap[], const int edges_a[],
                           const int edges_b[], const int edges_cap[],
                           GraphType::FGSeedsType& fg_nodes,
                           const int lambda) {
  GraphType::SrcSeedNode* it;

  GraphType *g = new GraphType(NUM_NODES, NUM_EDGES);

  g->add_node(NUM_NODES);

  /* add unary edges */
  for (unsigned int i = 0; i < g->get_node_num(); ++i) {
    int fg_node_id = get_node_source_id(i, fg_nodes, it);

    if (fg_node_id == INVALID_SRC_ID) {
      g->add_tweights(i, /* capacities */0, bg_cap[i] + lambda);
    } else {
      g->add_tweights(i, /* capacities */infty, 0);
      it->second.first = infty;
      it->second.second = bg_cap[i] + lambda;
    }

    g->set_node_source_idx(i, fg_node_id);
  }

  /* add pairwise edges */
  for (unsigned int i = 0; i < NUM_EDGES; ++i)
    g->add_edge(edges_a[i], edges_b[i], edges_cap[i], edges_cap[i]);

  return g;
}


int run_print_maxflow(GraphType* g, const GraphType::FGSeedsType& fg_nodes,
                      const unsigned int NUM_ROWS, const bool reuse_trees,
                      Block<GraphType::node_id>* changed_list) {
  int flow = g->maxflow(reuse_trees, changed_list);
  std::cout << "Computed Max flow" << std::endl;

  g->check_tree_integrity();

  for (unsigned int j = 0; j < fg_nodes.size(); ++j) {
    for (unsigned int k = 0; k < fg_nodes[j].size(); ++k) {
      std::cout << "Residual capacity of " << fg_nodes[j][k].first + 1
                << " (from seed " << j << ") : " << g->get_trcap(fg_nodes[j][k].first)
                << std::endl;
    }
  }

  std::cout << "Flow = " << flow << std::endl;
  std::cout << "Minimum cut:" << std::endl;
  for (int r = 0; r < NUM_ROWS; ++r) {
    for (int i = r; i < g->get_node_num(); i += NUM_ROWS) {
      if (g->what_segment(i) == GraphType::SOURCE)
        std::cout << "\tS";
      else
        std::cout << "\tT";
    }
    std::cout << std::endl;
  }

  return flow;
}


int get_node_source_id(const int node_id, GraphType::FGSeedsType& fg_nodes,
                       GraphType::SrcSeedNode* & it)
{
  int fg_node_id = INVALID_SRC_ID;
  it = NULL;

  /* iterate over all fg node sets to see if they are connected to some
   * source */
  for (unsigned int j = 0; j < fg_nodes.size() &&
                           fg_node_id == INVALID_SRC_ID; ++j) {
    for (unsigned int k = 0; k < fg_nodes[j].size(); ++k) {
      if (fg_nodes[j][k].first == node_id) {
        fg_node_id = j;
        it = &(fg_nodes[j][k]);
        break;
      }
    }
  }

  return fg_node_id;
}
