// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

#include <cstdlib>
#include <time.h>

void search_example_graph2() {
  const int SRC_SAME_THRESH = 3;
  const int SRC_DIFF_THRESH = 6;

  const float MIN_SRC_PRCNT = 0.3;
  const float MAX_SRC_PRCNT = 0.85;

  const float FG_NODE_PROB = 0.15;

  const int NUM_C_SECTS = 3;
  const int C_NODES_PER_SECTS = 2;
  const int NUM_NODES_R = 4;
  const int NUM_NODES_C = NUM_C_SECTS * C_NODES_PER_SECTS;
  const int NUM_NODES = NUM_NODES_R * NUM_NODES_C;

  const float EDGE_PROB = 0.6;
  const int INFTY = 100000;

  GraphType *g;

  static const int arr1[] = { 4, 6, 8, 10, 20, 30, 40 };
  std::vector<int> edge_cap(arr1, arr1 + sizeof(arr1) / sizeof(arr1[0]));

  static const int arr2[] = { 1, 3, 5, 7, 10, 20 };
  std::vector<int> lambda_cap(arr2, arr2 + sizeof(arr2) / sizeof(arr2[0]));

  std::vector<int> fg_nodes;

  std::vector<int> num_srcs_in_sect;

  std::vector<GraphType::termtype> graph_results;

  srand(time(NULL));

  std::vector< EdgeType > edges;
  std::vector<int> curr_lambda_cap(NUM_NODES);
  std::vector<int> curr_edge_cap;

  int max_tries = 100000;
  int curr_try = 0;

  /* iterate over different edge graphs */
  while (curr_try++ < max_tries) {
    /* create a random graph (the edge capacities are decided later */
    create_rand_edges(edges, EDGE_PROB, NUM_NODES_R, NUM_NODES_C);
    curr_edge_cap.assign(edges.size(), 0);

    int iter = 0;

    /* iterate over random edge and unary capacities for the graph generated */
    while (iter++ < 500) {
      /* create random edge capacities */
      for (unsigned int i = 0; i < edges.size(); ++i) {
        int chosen_type = rand() % edge_cap.size();
        curr_edge_cap[i] = edge_cap[chosen_type];
      }
      /* create random unary capacities */
      for (unsigned int i = 0; i < NUM_NODES; ++i) {
        int chosen_type = rand() % lambda_cap.size();
        curr_lambda_cap[i] = lambda_cap[chosen_type];
      }

      fg_nodes.clear();

      /* create list of fg nodes */
      for (unsigned int i = 0; i < NUM_NODES; ++i) {
        if (rand() <= RAND_MAX * FG_NODE_PROB) {
          fg_nodes.push_back(i);
        }
      }

      /* create the graph for the current fg seed, using the edge and
       * unary capacities generated above */
      g = create_graph(edges, curr_edge_cap, curr_lambda_cap,
                       fg_nodes, INFTY, NUM_NODES, false);
      /* compute the graph cut and store the result */
      graph_results = compute_display_result(g, NUM_NODES_R, NUM_NODES_C);
      delete g;

      num_srcs_in_sect.assign(NUM_C_SECTS, 0);

      /* check how many src nodes overlap with these two FG solutions*/
      for (unsigned int i = 0; i < NUM_NODES; ++i) {
        // find the section number
        int sect_idx = i / (C_NODES_PER_SECTS * NUM_NODES_R);
        if (graph_results[i] == GraphType::SOURCE)
          ++num_srcs_in_sect[sect_idx];
      }

      bool is_good_sol = true;
      std::cout << "[";
      for (unsigned int i = 0; i < NUM_C_SECTS; ++i) {
        float prcnt_src = (float)num_srcs_in_sect[i]/(C_NODES_PER_SECTS*NUM_NODES_R);
        std::cout << num_srcs_in_sect[i] << (i+1 == NUM_C_SECTS ? "" : ", ");
        if (prcnt_src < MIN_SRC_PRCNT || prcnt_src > MAX_SRC_PRCNT)
          is_good_sol = false;
      }
      std::cout << "]" << std::endl;

      std::cout << "-------------------- graph iter " << iter << " | curr try "
          << curr_try << " - Num edges " << edges.size()
          << " ----------------------" << std::endl;

      //if (src_same == NUM_FGS) {
      if (is_good_sol) {
        curr_try = max_tries + 1;
        break;
      }
    }
  }

  std::cout << "const int NUM_NODES = " << NUM_NODES_R*NUM_NODES_C << ";\n";
  std::cout << "const int NUM_EDGES = " << edges.size() << ";\n";
  std::cout << "int edges_a[]   = {";
  for (unsigned int i = 0; i < edges.size(); ++i)
    std::cout << edges[i].first << (i+1 == edges.size() ? "" : ", ");
  std::cout << "};\nint edges_b[]   = {";
  for (unsigned int i = 0; i < edges.size(); ++i)
    std::cout << edges[i].second << (i+1 == edges.size() ? "" : ", ");
  std::cout << "};\nint edges_cap[] = {";
  for (unsigned int i = 0; i < curr_edge_cap.size(); ++i)
    std::cout << curr_edge_cap[i] << (i+1 == curr_edge_cap.size() ? "" : ", ");
  std::cout << "};" << std::endl;

  std::cout << "int bg_cap[] = {";
  for (unsigned int i = 0; i < curr_lambda_cap.size(); ++i)
    std::cout << curr_lambda_cap[i] << (i+1 == curr_lambda_cap.size() ? "" : ", ");
  std::cout << "};" << std::endl;

  std::cout << "int fg_nodes[] = {";
  for (unsigned int i = 0; i < fg_nodes.size(); ++i)
    std::cout << fg_nodes[i] << (i+1 == fg_nodes.size() ? "" : ", ");
  std::cout << "};" << std::endl;

  std::cout << "Latex Tikz" << std::endl;
  for (unsigned int i = 0; i < curr_lambda_cap.size(); ++i) {
    std::cout << "\\node[";

    bool marked_fg = false;
    for (unsigned int k = 0; k < fg_nodes.size(); ++k) {
      if (fg_nodes[k] == i) {
        std::cout << "fgnode";
        marked_fg = true;
        break;
      }
    }

    if (!marked_fg)
      std::cout << "bgnode";

    std::cout << "] (" << i + 1 << ") at (" << i / NUM_NODES_R << ","
        << (NUM_NODES_R - 1 - (i % NUM_NODES_R)) << ") {\\nodetxt{" << i + 1
        << "}{$" << (marked_fg ? "" : "-") << curr_lambda_cap[i] << "$}{}};"
        << std::endl;
  }
  std::cout << "\n% capacity edges" << std::endl;
  for (unsigned int i = 0; i < edges.size(); ++i) {
    std::cout << "\\draw[conn=" << curr_edge_cap[i] << "] (" << edges[i].first + 1
        << ") to (" << edges[i].second + 1 << ");" << std::endl;
  }
}
