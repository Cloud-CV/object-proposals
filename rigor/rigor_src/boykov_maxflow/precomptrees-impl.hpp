// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

/* precomptrees.cpp */

#ifndef __PRECOMPTREESIMPL_HPP__
#define __PRECOMPTREESIMPL_HPP__

#include <iostream>
#include <fstream>
#include <boost/format.hpp>

#include "graph.h"

using boost::format;


/*
  special constants for node->parent. Duplicated in graph.cpp, both should match!
*/
#define TERMINAL ( (arc *) 1 )    /* to terminal */
#define ORPHAN   ( (arc *) 2 )    /* orphan */


template<typename captype, typename tcaptype, typename flowtype>
 void Graph<captype, tcaptype, flowtype>::transform_seed_trees(
    const int keep_src_id, const SrcSeedList* remove_seed_list)
{
  node *i;

  typename SrcSeedList::const_iterator it_orig_cap, it_new_cap;

  // useful for maxflow_reuse_trees_init()
  curr_src_origin_idx = keep_src_id;

  // iterate over all the fg seed nodes which need to be converted from Seed S
  // trees to T sink trees. This loop looks at the fg seeds which need to be
  // discarded: it changes its residual capacities; adjusts the flow and adds
  // to the queue for being marked as the sink tree
  for (it_orig_cap = remove_seed_list[0].begin(),
       it_new_cap = remove_seed_list[1].begin();
       it_orig_cap != remove_seed_list[0].end(); ++it_orig_cap, ++it_new_cap) {
    // get the pointer to the current node
    i = nodes + it_orig_cap->first;

    tcaptype new_sink_residual_cap, new_src_residual_cap;

    // get all the capacities
    tcaptype residual_cap = get_trcap(i - nodes);
    tcaptype orig_src_cap = it_orig_cap->second.first;
    //tcaptype orig_sink_cap = it_orig_cap->second.second;
    tcaptype new_src_cap = it_new_cap->second.first;
    tcaptype new_sink_cap = it_new_cap->second.second;

    tcaptype flow_s = orig_src_cap - residual_cap;

    // we can directly set the residual capacity on the sink link because
    // we know there was no capacity on it originally i.e.
    // c_{it} = r_{it} = f_{it} = 0   /   orig_sink_cap := 0
    new_sink_residual_cap = new_sink_cap;

    // if the capacity is reduced only to the extent that it can still
    // accomodate the old flow (see Kohli and Torr, PAMI 2007)
    if (new_src_cap >= flow_s) {
      new_src_residual_cap = new_src_cap - flow_s;
    } else {
      /* if not then add an alpha value to the sink capacity */
      new_src_residual_cap = 0;
      new_sink_residual_cap += flow_s - new_src_cap;
      flow -= flow_s - new_src_cap;
    }

    set_trcap(it_orig_cap->first, new_src_residual_cap - new_sink_residual_cap);

    //std::cout << "Node " << (node_id)(i - nodes) << ": Old " << residual_cap << ", New " << get_trcap(i - nodes) << std::endl;

    // push to queue according to whether they have positive residual capacity
    // or negative. If they have negative residual capacity on its t link then
    // the node and its children can be converted to Sink T tree in the
    // upcoming while loop. Otherwise it needs to be added to the Source S
    // tree
    /*
    i->parent = TERMINAL;
    if (get_trcap(i - nodes) < 0)
      t_tree_children.push(i);
    else if (get_trcap(i - nodes) > 0)
      s_tree_children.push(i);
    */
    if (get_trcap(i - nodes) != 0)
      i->parent = TERMINAL;
    else {
      i->src_origin_idx = INVALID_SRC_ID;
      i->parent = NULL;
    }
  }

  node* n_ptr;
  NodeEditSet tree_nodes;

  // iterate over all nodes and add terminal and free nodes to the tree_nodes
  // list (and indicate as root in orig_root_nodes)
  for (n_ptr = nodes; n_ptr < node_last; ++n_ptr) {
    // skip node if its not a terminal or free node
    if (n_ptr->parent == TERMINAL || n_ptr->parent == NULL) {
      tree_nodes.insert(n_ptr);
    }
  }

  normalize_tree(tree_nodes);

  // iterate over all the nodes and set as free if they were neither part of
  // seed src or the converted sink trees
  /*for (i = nodes; i < node_last; i++) {
    if (i->src_origin_idx != keep_src_id && i->src_origin_idx != INVALID_SRC_ID &&
        i->is_sink != 1 && i->tr_cap == 0) {
      //if (PRINT_DEBUG && ((node_id)(i - nodes) == 41 || (node_id)(i - nodes) == 69 || (node_id)(i - nodes) == 99 || (node_id)(i - nodes) == 70))
      //  std::cout << "\tMarking " << i - nodes << " as free" << std::endl;

      i->parent = NULL;
      i->src_origin_idx = INVALID_SRC_ID;
      //mark_node(i - nodes);

      // mark all the neighboring nodes as active too
      for (arc* a = i->first; a; a = a->next) {
        mark_node(a->head - nodes);
        //std::cout << a->head - nodes << ", ";
      }
    }
  } */
}

template<typename captype, typename tcaptype, typename flowtype>
  void Graph<captype, tcaptype, flowtype>::set_active_normalization()
{
  node* n_ptr;
  node* neigh_ptr;

  // iterate over all nodes to see which ones should be set to active
  for (n_ptr = nodes; n_ptr < node_last; ++n_ptr) {
    //set_active(n_ptr);
    // if node doesn't belong to a tree after normalization, don't mark it
    //  active. A neighboring node, which belongs to a tree, and hence can
    //  grow into it would be marked when it sees this node
    if (n_ptr->parent == NULL || n_ptr->parent == ORPHAN) {
      continue;
    } else {
      // we now know that n_ptr belongs to a valid tree

      // iterate over each neighbor to see if there is a reason to set this
      // node active
      for (arc* a = n_ptr->first; a; a = a->next) {
        neigh_ptr = a->head;

        // neighbor is free or orphan (i.e. it doesnt belong to a tree) set
        // this node as active, so that the neighbor can be grown into
        if (neigh_ptr->parent == NULL || neigh_ptr->parent == ORPHAN) {
          set_active(n_ptr);
          break;
        } else {
          // if the neighbor belongs to an opposite tree
          if (n_ptr->is_sink != neigh_ptr->is_sink) {
            // if there is an unsaturated path between the nodes
            //  if u is in src then the arc u->v should be unsaturated
            //  if u is in sink then the arc v->u should be unsaturated
            if ((!n_ptr->is_sink && a->r_cap) ||
                (n_ptr->is_sink && a->sister->r_cap)) {
              // if the neighbor is active, then no need to set this node
              //  to active. It will get noticed anyways by neighbor anyways
              //if (!neigh_ptr->next) {
                set_active(n_ptr);
                break;
              //}
            }
          }
        }
      }
    }
  }
}

template<typename captype, typename tcaptype, typename flowtype>
  void Graph<captype, tcaptype, flowtype>::normalize_node(node* const n_ptr)
{
  captype up_rcap, dwn_rcap;

  bool is_root = (n_ptr->parent == TERMINAL || n_ptr->parent == NULL || n_ptr->parent == ORPHAN);

  // note down the original sink/src value
  int old_is_sink = -1;
  if (n_ptr->parent != NULL && n_ptr->parent != ORPHAN)
    old_is_sink = n_ptr->is_sink;

  // check if the parent was sink/src
  int parent_is_sink = -1;
  if (!is_root && n_ptr->parent->head->parent != NULL &&
                  n_ptr->parent->head->parent != ORPHAN)
    parent_is_sink = n_ptr->parent->head->is_sink;

  // note the residual capacities both on tr and n links
  if (!is_root) {
    up_rcap = n_ptr->parent->r_cap;
    dwn_rcap = n_ptr->parent->sister->r_cap;
  }
  tcaptype trcap = get_trcap(n_ptr-nodes);

  /*
  if (trcap != 0) {
    n_ptr->next = NULL;
    n_ptr->is_marked = 0;
    std::cout << " | " << (!n_ptr->next);
    set_active(n_ptr);
  }*/

  // if the node can be connected to the parent, then update values,
  // otherwise either set to free or connect to terminal if t residual
  // capacity preset TIME
  if ((parent_is_sink == 0 && dwn_rcap > 0 && trcap >= 0) ||
      (parent_is_sink == 1 && up_rcap > 0 && trcap <= 0)) {
    n_ptr->is_sink = parent_is_sink;
    n_ptr->src_origin_idx = n_ptr->parent->head->src_origin_idx;
    n_ptr->TS = TIME + 1;
    n_ptr->DIST = n_ptr->parent->head->DIST + 1;
  } else if (trcap != 0) {
    // directly connect to terminal
    n_ptr->is_sink = trcap < 0;
    n_ptr->src_origin_idx = n_ptr->is_sink ? INVALID_SRC_ID : curr_src_origin_idx;
    n_ptr->parent = TERMINAL;
    n_ptr->TS = TIME + 1;
    n_ptr->DIST = 1;
  } else {
    // set free
    n_ptr->parent = NULL;
    n_ptr->src_origin_idx = INVALID_SRC_ID;

    // also mark node so it comes in active list
    //mark_node(n_ptr - nodes);
  }

  // get the new src/sink value
  int new_is_sink = -1;
  if (n_ptr->parent != NULL && n_ptr->parent != ORPHAN)
    new_is_sink = n_ptr->is_sink;

  // if the src/sink value change, then mark itself and all the neighboring
  // nodes
  if (new_is_sink != old_is_sink) {
    //mark_node(n_ptr - nodes);
    add_to_changed_list(n_ptr);

    // mark all neighboring nodes with different src/sink id as active too
   /* for (arc* a = n_ptr->first; a; a = a->next) {
      int neigh_is_sink = -1;
      if (a->head->parent != NULL && a->head->parent != ORPHAN)
        neigh_is_sink = a->head->is_sink;

      if (neigh_is_sink != new_is_sink)
        mark_node(a->head - nodes);
    }*/
  }
}


template<typename captype, typename tcaptype, typename flowtype>
  void Graph<captype, tcaptype, flowtype>::normalize_tree(NodeEditSet& tree_nodes)
{
  node* n_ptr;
  node* tree_ptr;
  captype up_rcap, dwn_rcap;

  // BFS over all trees
  for (n_ptr = nodes; n_ptr < node_last; ++n_ptr) {
    // check if
    bool is_root = (n_ptr->parent == TERMINAL || n_ptr->parent == NULL);

    // skip node if its not a terminal node
    if (is_root) {
      // if src root node, then explore the whole tree
      std::queue<node*> tree_queue;

      tree_queue.push(n_ptr);

      // BFS over whole tree
      while (!tree_queue.empty()) {
        tree_ptr = tree_queue.front();
        tree_queue.pop();

        bool node_normalized = false;

        // if it was suggested that the node was changed
        if (tree_nodes.count(tree_ptr) != 0) {
          normalize_node(tree_ptr);
          node_normalized = true;

          tree_nodes.erase(tree_ptr);
        }

        // iterate over all the nodes connected to this node, and add children
        for (arc* a=tree_ptr->first; a; a=a->next) {
          if (a->head->parent != TERMINAL && a->head->parent != ORPHAN &&
              a->head->parent != NULL && a->head->parent->head == tree_ptr) {
            // if the current arc points to a node which is a child
            tree_queue.push(a->head);

            if (node_normalized) {
              tree_nodes.insert(a->head);
            }
          }
        }
      }
    }
  }

  // mark the relevant mpdes active
  set_active_normalization();
}

template<typename captype, typename tcaptype, typename flowtype>
  void Graph<captype, tcaptype, flowtype>::update_capacities(const size_t& num_params,
                                            const tcaptype* const nonlambda_s,
                                            const tcaptype* const nonlambda_t,
                                            const tcaptype* const lambda_s,
                                            const tcaptype* const lambda_t,
                                            const tcaptype* const lambda_range,
                                            const int lambda_idx, const int lambda_inc)
{
  NodeEditSet tree_nodes;

  /* update unary capacity edges (t-links) */
  for (node_id var_i = 0; var_i < node_num; ++var_i) {
    // the previous unary capacities
    tcaptype s_cap_prv = nonlambda_s[var_i] +
        lambda_range[lambda_idx-lambda_inc]*lambda_s[var_i];
    tcaptype t_cap_prv = nonlambda_t[var_i] +
        lambda_range[num_params-(lambda_idx-lambda_inc)-1]*lambda_t[var_i];
    tcaptype old_cap_diff = s_cap_prv - t_cap_prv;

    // the new unary capacities
    tcaptype s_cap = nonlambda_s[var_i] +
        lambda_range[lambda_idx]*lambda_s[var_i];
    tcaptype t_cap = nonlambda_t[var_i] +
        lambda_range[num_params-lambda_idx-1]*lambda_t[var_i];
    tcaptype new_cap_diff = s_cap - t_cap;


    // reparameterize the unary
    reparam_unary(var_i, old_cap_diff, new_cap_diff);

    if ((nodes[var_i].tr_cap > 0 && nodes[var_i].is_sink) ||
        (nodes[var_i].tr_cap < 0 && !nodes[var_i].is_sink)) {
      tree_nodes.insert(nodes + var_i);
      add_to_changed_list(nodes + var_i);
    }
  }

  normalize_tree(tree_nodes);
}


template<typename captype, typename tcaptype, typename flowtype>
  bool Graph<captype, tcaptype, flowtype>::check_tree_integrity(const std::string& filename) const
{
  //std::cout << "Checking integrity of trees [should be run after maxflow() "
  //          << "or transform_seed_trees()] - " << filename << std::endl;

  std::ofstream tree_out;
  if (!filename.empty()) tree_out.open(filename.c_str(), std::ios::trunc);

  /* vector to check if each node is accounted for */
  std::vector<int> nodes_checked(node_num, 0);
  int num_nodes_checked = 0;
  tcaptype trcap;
  node_id curr_i;

  /* iterate over all nodes */
  for (node_id i = 0; i < node_num; ++i) {
    node* n_ptr = nodes + i;
    const int curr_src_idx = n_ptr->src_origin_idx;

    // skip node if its not a terminal node
    if (n_ptr->parent == TERMINAL) {
      if (!n_ptr->is_sink) {
        // if src tree
        if (!filename.empty()) tree_out << "Source (" << n_ptr->src_origin_idx << ") rooted at ";

        // if src root node, then explore the whole tree
        std::queue<node*> src_nodes;

        curr_i = n_ptr - nodes;
        src_nodes.push(n_ptr);

        // this node shouldn't have been encountered before
        if (nodes_checked[curr_i] != 0)
          std::cerr << "I have encountered node " << curr_i << " before"
                    << std::endl;
        // check if the src_idx is a valid one
        if (curr_src_idx == INVALID_SRC_ID) {
          std::cerr << curr_i << " should be part of some source "
                    << " tree, not " << INVALID_SRC_ID << std::endl;
          nodes_checked[curr_i] = -1;
        }

        // BFS over whole tree
        while (!src_nodes.empty()) {
          n_ptr = src_nodes.front();
          curr_i = n_ptr - nodes;
          src_nodes.pop();

          if (!filename.empty()) tree_out << curr_i << ", ";

          // iterate over all the arcs of this node and search for children
          for (arc* a=n_ptr->first; a; a=a->next) {
            if (a->head->parent != TERMINAL && a->head->parent != ORPHAN &&
                a->head->parent != NULL && a->head->parent->head == n_ptr) {
              // if the current arc points to a node which is a child
              node_id conn_i = (node_id)(a->head - nodes);
              src_nodes.push(a->head);

              // this node shouldn't have been encountered before
              if (nodes_checked[conn_i] != 0)
                std::cerr << "I have encountered node " << conn_i << " before"
                          << std::endl;

              // there should be positive residual on the edge connecting
              // to the parent
              if (a->r_cap <= 0) {
                std::cerr << curr_i << "->" << conn_i << " needs to have "
                          << "positive residual capacity because the edge is"
                          << " part of the source tree (" << a->r_cap << ")"
                          << std::endl;
                nodes_checked[conn_i] = -1;
              }
            }
          }

          trcap = get_trcap(curr_i);
          // check if the node connecting to terminal has positive tr cap
          if (trcap < 0) {
            std::cerr << curr_i << " cannot have residual capacity to the sink "
                      << "(" << trcap << ") since it is part of the src tree"
                      << std::endl;
            nodes_checked[curr_i] = -1;
          }
          // check the id of the src origin idx
          if (n_ptr->src_origin_idx != curr_src_idx) {
            std::cerr << curr_i << " should be part of the " << curr_src_idx
                      << " source tree, not " << n_ptr->src_origin_idx << std::endl;
            nodes_checked[curr_i] = -1;
          }
          // check if the node is not sink
          if (n_ptr->is_sink) {
            std::cerr << curr_i << " should not be part of the sink side of the cut"
                      << " because it is part of the src tree" << std::endl;
            nodes_checked[curr_i] = -1;
          }

          // if node still good, mark it as having good integrity
          if (nodes_checked[curr_i] == 0)
            nodes_checked[curr_i] = 1;

          ++num_nodes_checked;
        }

        if (!filename.empty()) tree_out << std::endl;
      } else {
        // if sink tree
        if (!filename.empty()) tree_out << "Sink rooted at ";

        // if sink root node, then explore the whole tree
        std::queue<node*> sink_nodes;

        curr_i = n_ptr - nodes;
        sink_nodes.push(n_ptr);

        // this node shouldn't have been encountered before
        if (nodes_checked[curr_i] != 0)
          std::cerr << "I have encountered node " << curr_i << " before"
                    << std::endl;
        // check if the src_idx is invalid since we are sink
        if (curr_src_idx != INVALID_SRC_ID) {
          std::cerr << curr_i << " should be part of sink tree, not "
                    << INVALID_SRC_ID << std::endl;
          nodes_checked[curr_i] = -1;
        }

        // BFS over whole tree
        while (!sink_nodes.empty()) {
          n_ptr = sink_nodes.front();
          curr_i = n_ptr - nodes;
          sink_nodes.pop();

          if (!filename.empty()) tree_out << curr_i << ", ";

          // iterate over all the arcs of this node and search for children
          for (arc* a=n_ptr->first; a; a=a->next) {
            if (a->head->parent != TERMINAL && a->head->parent != ORPHAN &&
                a->head->parent != NULL && a->head->parent->head == n_ptr) {
              // if the current arc points to a node which is a child
              node_id conn_i = (node_id)(a->head-nodes);
              sink_nodes.push(a->head);

              // this node shouldn't have been encountered before
              if (nodes_checked[conn_i] != 0)
                std::cerr << "I have encountered node " << conn_i << " before"
                          << std::endl;

              // there should be positive residual on the edge connecting
              // to the parent
              if (a->sister->r_cap <= 0) {
                std::cerr << conn_i << "->" << curr_i << " needs to have "
                          << "positive residual capacity because the edge is"
                          << " part of the sink tree (" << a->r_cap << ")"
                          << std::endl;
                nodes_checked[conn_i] = -1;
              }
            }
          }

          trcap = get_trcap(curr_i);
          // check if the node connecting to terminal has negative tr cap
          if (trcap > 0) {
            std::cerr << curr_i << " cannot have residual capacity to the src "
                      << "(" << trcap << ") since it is part of the sink tree"
                      << std::endl;
            nodes_checked[curr_i] = -1;
          }
          // check the id of the src origin idx
          if (n_ptr->src_origin_idx != curr_src_idx) {
            std::cerr << curr_i << " should be part of the " << curr_src_idx
                      << " sink tree, not " << n_ptr->src_origin_idx << std::endl;
            nodes_checked[curr_i] = -1;
          }
          // check if the node is not sink
          if (!n_ptr->is_sink) {
            std::cerr << curr_i << " should not be part of the src side of the cut"
                      << " because it is part of the sink tree" << std::endl;
            nodes_checked[curr_i] = -1;
          }

          // if node still good, mark it as having good integrity
          if (nodes_checked[curr_i] == 0)
            nodes_checked[curr_i] = 1;

          ++num_nodes_checked;
        }

        if (!filename.empty()) tree_out << std::endl;
      }
    }
  }

  /* all remaining nodes which are not part of some tree should be free */
  for (node_id i=0; i < node_num; ++i) {
    node* n_ptr = nodes + i;

    if (nodes_checked[i] == 0) {
      nodes_checked[i] = 1;

      if (n_ptr->parent != NULL) {
        std::cerr << i << " should be a free node because it is not part of "
                  << "any tree" << std::endl;
        nodes_checked[i] = -1;
      }

      tcaptype trcap = get_trcap(i);
      if (trcap != 0) {
        std::cerr << i << " is a free node at the end of maxflow so should "
                  << "have zero t residual capacity (" << trcap << ")"
                  << std::endl;
        nodes_checked[i] = -1;
      }

      // check if the src_idx is invalid since we are free
      if (n_ptr->src_origin_idx != INVALID_SRC_ID) {
        std::cerr << curr_i << " should be free, not part of tree "
                  << INVALID_SRC_ID << std::endl;
        nodes_checked[curr_i] = -1;
      }

      if (!filename.empty()) tree_out << "Free node " << i << std::endl;

      ++num_nodes_checked;
    }
  }

  int nodes_wrong = 0;
  for (node_id i=0; i < node_num; ++i) {
    if (nodes_checked[i] == -1)
      ++nodes_wrong;
  }

  if (!filename.empty()) tree_out.close();

  test_consistency();

  gassert(nodes_wrong == 0, "errors while checking tree integrity");

  return (nodes_wrong == 0);
}

#endif