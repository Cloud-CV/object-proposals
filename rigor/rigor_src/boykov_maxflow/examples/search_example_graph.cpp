// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "examples.h"

#include <cstdlib>
#include <time.h>

void search_example_graph() {
  const int SRC_SAME_THRESH = 3;
  const int SRC_DIFF_THRESH = 6;

  const int NUM_NODES_R = 8;
  const int NUM_NODES_C = 8;
  const int NUM_NODES = NUM_NODES_R * NUM_NODES_C;

  const float EDGE_PROB = 0.6;
  const int INFTY = 100000;

  GraphType *g;

  static const int arr1[] = { 4, 6, 8, 10, 20, 30, 40 };
  std::vector<int> edge_cap(arr1, arr1 + sizeof(arr1) / sizeof(arr1[0]));

  static const int arr2[] = { 1, 3, 5, 7, 10 };
  std::vector<int> lambda_cap(arr2, arr2 + sizeof(arr2) / sizeof(arr2[0]));

  const int NUM_FGS = 3;
  static const int fg_nodes1[] = { 10, 11 };
  static const int fg_nodes2[] = { 42 };
  static const int fg_nodes3[] = { 29, 37, 38 };
  std::vector < std::vector<int> > fg_nodes;
  fg_nodes.push_back(
      std::vector<int>(fg_nodes1,
                       fg_nodes1 + sizeof(fg_nodes1) / sizeof(fg_nodes1[0])));
  fg_nodes.push_back(
      std::vector<int>(fg_nodes2,
                       fg_nodes2 + sizeof(fg_nodes2) / sizeof(fg_nodes2[0])));
  fg_nodes.push_back(
      std::vector<int>(fg_nodes3,
                       fg_nodes3 + sizeof(fg_nodes3) / sizeof(fg_nodes3[0])));

  std::vector < std::vector<GraphType::termtype> > graph_results(NUM_FGS);

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

      /* go over each fg seed and compute its cut */
      for (unsigned int i = 0; i < NUM_FGS; ++i) {
        /* create the graph for the current fg seed, using the edge and
         * unary capacities generated above */
        g = create_graph(edges, curr_edge_cap, curr_lambda_cap,
                         fg_nodes[i], INFTY, NUM_NODES);
        /* compute the graph cut and store the result */
        graph_results[i] = compute_display_result(g, NUM_NODES_R, NUM_NODES_C);
        delete g;
      }

      int src_same = 0;
      std::vector<int> src_diffs(NUM_FGS, 0);

      /* iterate over all nodes to see if every fg solution src matches up to another
       * fg solution for atleast SRC_SAME_THRESH */
      std::vector<bool> fg_meets_thresh(NUM_FGS, false);
      for (unsigned int fg1 = 0; fg1 < NUM_FGS - 1; ++fg1) {
        for (unsigned int fg2 = fg1+1; fg2 < NUM_FGS; ++fg2) {
          int src_pair_same = 0;
          /* check how many src nodes overlap with these two FG solutions*/
          for (unsigned int i = 0; i < NUM_NODES; ++i) {
            if (graph_results[fg1][i] == GraphType::SOURCE &&
                graph_results[fg2][i] == GraphType::SOURCE) {
              src_pair_same++;
            }
          }

          if (src_pair_same >= SRC_SAME_THRESH) {
            fg_meets_thresh[fg1] = true;
            fg_meets_thresh[fg2] = true;
          }
        }
      }
      for (unsigned int i = 0; i < NUM_FGS; ++i) {
        if (fg_meets_thresh[i])
          src_same++;
      }

      /* iterate over all fgs to see how much different they are from others */
      for (unsigned int fg1 = 0; fg1 < NUM_FGS; ++fg1) {
        /* iterate over all nodes */
        for (unsigned int i = 0; i < NUM_NODES; ++i) {
          bool this_fg_src_only = true;
          /* if in src side of the cut for this fg */
          if (graph_results[fg1][i] == GraphType::SOURCE) {
            /* check all other fg seeds solutions to see if another one has the
             * same node in the src side of the cut */
            for (unsigned int fg2 = 0; fg2 < NUM_FGS; ++fg2) {
              if (fg1 != fg2 && graph_results[fg2][i] == GraphType::SOURCE) {
                this_fg_src_only = false;
                break;
              }
            }

            if (this_fg_src_only)
              src_diffs[fg1]++;
          }
        }
      }

      std::cout << "Number of FG solutions which overlap with atleast " <<
                   SRC_SAME_THRESH << " nodes with some othe sol: " << src_same << std::endl;
      for (unsigned int i = 0; i < NUM_FGS; ++i) {
        std::cout << "Number of isolated src for FG " << i + 1 << " : " << src_diffs[i] << std::endl;
      }

      std::cout << "-------------------- graph iter " << iter << " | curr try "
          << curr_try << " - Num edges " << edges.size()
          << " ----------------------" << std::endl;

      //if (src_same == NUM_FGS) {
      if (src_same > 0) {
        bool all_thresh = true;

        for (unsigned int j = 0; j < NUM_FGS; ++j) {
          if (src_diffs[j] < SRC_DIFF_THRESH) {
            all_thresh = false;
            break;
          }
        }

        if (all_thresh) {
          curr_try = max_tries + 1;
          break;
        }
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

  std::cout << "Latex Tikz" << std::endl;
  for (unsigned int i = 0; i < curr_lambda_cap.size(); ++i) {
    std::cout << "\\node[";

    bool marked_fg = false;
    for (unsigned int j = 0; j < NUM_FGS; ++j) {
      for (unsigned int k = 0; k < fg_nodes[j].size(); ++k) {
        if (fg_nodes[j][k] == i) {
          std::cout << "fg" << j + 1 << "node";
          marked_fg = true;
          break;
        }
      }
    }

    if (!marked_fg)
      std::cout << "bgnode";

    std::cout << "] (" << i + 1 << ") at (" << i / NUM_NODES_R << ","
        << (NUM_NODES_R - 1 - (i % NUM_NODES_R)) << ") {\\nodetxt{" << i + 1
        << "}{$-" << curr_lambda_cap[i] << "$}{}};" << std::endl;
  }
  std::cout << "\n% capacity edges" << std::endl;
  for (unsigned int i = 0; i < edges.size(); ++i) {
    std::cout << "\\draw[conn=" << curr_edge_cap[i] << "] (" << edges[i].first + 1
        << ") to (" << edges[i].second + 1 << ");" << std::endl;
  }
}
