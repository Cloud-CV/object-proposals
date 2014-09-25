// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#ifndef _EXAMPLES_EXAMPLES_H_
#define _EXAMPLES_EXAMPLES_H_

#include <iostream>
#include <vector>
#include <algorithm>

#include "../graph.h"


typedef Graph<int, int, int> GraphType;

const int infty = 100000;

void create_seed_list(const unsigned int fg_nodes[],
                      const unsigned int NUM_ELEMS,
                      GraphType::SrcSeedList& seed_list);

GraphType* construct_graph(const int NUM_NODES, const int NUM_EDGES,
                           const int bg_cap[], const int edges_a[],
                           const int edges_b[], const int edges_cap[],
                           GraphType::FGSeedsType& fg_nodes,
                           const int lambda=0);

int run_print_maxflow(GraphType* g, const GraphType::FGSeedsType& fg_nodes,
                      const unsigned int NUM_ROWS,
                      const bool reuse_trees=false,
                      Block<GraphType::node_id>* changed_list=NULL);

GraphType* generate_example3_graph(GraphType::FGSeedsType& fg_nodes,
                                   unsigned int& node_rows,
                                   const int use_seed[], int lambda=0);
GraphType* generate_example4_graph(GraphType::FGSeedsType& fg_nodes,
                                   unsigned int& node_rows,
                                   const int use_seed[], int lambda=0);
GraphType* generate_example5_graph(GraphType::FGSeedsType& fg_nodes,
                                   unsigned int& node_rows,
                                   const int use_seed[], int lambda=0);

void example1();
void example2();
void example3();
void example4();
void example5();


typedef Graph<int, int, int> GraphType;
typedef std::pair<int, int> EdgeType;

void create_rand_edges(std::vector< EdgeType >& edges,
                      const float EDGE_PROB, const int NUM_NODES_R,
                      const int NUM_NODES_C);
GraphType* create_graph(std::vector< EdgeType >& edges,
                        std::vector<int>& curr_edge_cap,
                        std::vector<int>& curr_lambda_cap,
                        const std::vector<int>& fg_nodes, const int INFTY,
                        const int NUM_NODES, const bool fg_cap_inf=true);
std::vector<GraphType::termtype> compute_display_result(GraphType* g,
                                                        const int NUM_NODES_R,
                                                        const int NUM_NODES_C);

void search_example_graph();
void search_example_graph2();

int get_node_source_id(const int node_id, GraphType::FGSeedsType& fg_nodes,
                       GraphType::SrcSeedNode* & it);

#endif // _EXAMPLES_EXAMPLES_H_
