// Edited by:
//  @authors:     Ahmad Humayun
//  @contact:     ahumayun@cc.gatech.edu
//  @affiliation: Georgia Institute of Technology
//  @date:        Fall 2013 - Summer 2014


/* graph.cpp */

#ifndef __GRAPHIMPL_HPP__
#define __GRAPHIMPL_HPP__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "graph.h"

/*
	special constants for node->parent. Duplicated in maxflow.cpp, both should match!
*/
#define TERMINAL ( (arc *) 1 )		/* to terminal */
#define ORPHAN   ( (arc *) 2 )		/* orphan */

template <typename captype, typename tcaptype, typename flowtype> 
	Graph<captype, tcaptype, flowtype>::Graph(int node_num_max, int edge_num_max, void (*err_function)(const char *))
	: node_num(0),
	  nodeptr_block(NULL),
	  error_function(err_function)
{
  curr_src_origin_idx = INVALID_SRC_ID;
	if (node_num_max < 16) node_num_max = 16;
	if (edge_num_max < 16) edge_num_max = 16;

	nodes = (node*) malloc(node_num_max*sizeof(node));
	arcs = (arc*) malloc(2*edge_num_max*sizeof(arc));
	if (!nodes || !arcs) { if (error_function) (*error_function)("Not enough memory!"); exit(1); }

	node_last = nodes;
	node_max = nodes + node_num_max;
	arc_last = arcs;
	arc_max = arcs + 2*edge_num_max;

	maxflow_iteration = 0;
	flow = 0;
}

template <typename captype, typename tcaptype, typename flowtype> 
	Graph<captype,tcaptype,flowtype>::~Graph()
{
	if (nodeptr_block) 
	{ 
		delete nodeptr_block; 
		nodeptr_block = NULL; 
	}
	free(nodes);
	free(arcs);
}

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::reset()
{
	node_last = nodes;
	arc_last = arcs;
	node_num = 0;

	if (nodeptr_block) 
	{ 
		delete nodeptr_block; 
		nodeptr_block = NULL; 
	}

	maxflow_iteration = 0;
	flow = 0;
}

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::reallocate_nodes(int num)
{
	int node_num_max = (int)(node_max - nodes);
	node* nodes_old = nodes;

	node_num_max += node_num_max / 2;
	if (node_num_max < node_num + num) node_num_max = node_num + num;
	nodes = (node*) realloc(nodes_old, node_num_max*sizeof(node));
	if (!nodes) { if (error_function) (*error_function)("Not enough memory!"); exit(1); }

	node_last = nodes + node_num;
	node_max = nodes + node_num_max;

	if (nodes != nodes_old)
	{
		node* i;
		arc* a;
		for (i=nodes; i<node_last; i++)
		{
			if (i->next) i->next = (node*) ((char*)i->next + (((char*) nodes) - ((char*) nodes_old)));
		}
		for (a=arcs; a<arc_last; a++)
		{
			a->head = (node*) ((char*)a->head + (((char*) nodes) - ((char*) nodes_old)));
		}
	}
}

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::reallocate_arcs()
{
	int arc_num_max = (int)(arc_max - arcs);
	int arc_num = (int)(arc_last - arcs);
	arc* arcs_old = arcs;

	arc_num_max += arc_num_max / 2; if (arc_num_max & 1) arc_num_max ++;
	arcs = (arc*) realloc(arcs_old, arc_num_max*sizeof(arc));
	if (!arcs) { if (error_function) (*error_function)("Not enough memory!"); exit(1); }

	arc_last = arcs + arc_num;
	arc_max = arcs + arc_num_max;

	if (arcs != arcs_old)
	{
		node* i;
		arc* a;
		for (i=nodes; i<node_last; i++)
		{
			if (i->first) i->first = (arc*) ((char*)i->first + (((char*) arcs) - ((char*) arcs_old)));
			if (i->parent && i->parent != ORPHAN && i->parent != TERMINAL) i->parent = (arc*) ((char*)i->parent + (((char*) arcs) - ((char*) arcs_old)));
		}
		for (a=arcs; a<arc_last; a++)
		{
			if (a->next) a->next = (arc*) ((char*)a->next + (((char*) arcs) - ((char*) arcs_old)));
			a->sister = (arc*) ((char*)a->sister + (((char*) arcs) - ((char*) arcs_old)));
		}
	}
}

// the deep copy constructor
template <typename captype, typename tcaptype, typename flowtype>
  Graph<captype,tcaptype,flowtype>::Graph(const Graph<captype,tcaptype,flowtype>& src_graph)
{
  // shallow copy all static objects
  node_num = src_graph.node_num;
  error_function = src_graph.error_function;
  flow = src_graph.flow;
  maxflow_iteration = src_graph.maxflow_iteration;
  TIME = src_graph.TIME;

  // memory allocation for nodes (and blindly copy memory)
  int node_num_max = (int)(src_graph.node_max - src_graph.nodes);
  nodes = (node*) malloc(node_num_max*sizeof(node));
  if (!nodes) { if (error_function) (*error_function)("Not enough memory!"); exit(1); }
  memcpy(nodes, src_graph.nodes, node_num_max*sizeof(node));

  node_last = nodes + node_num;
  node_max = nodes + node_num_max;

  // memory allocation for arcs (and blindly copy memory)
  int arc_num_max = (int)(src_graph.arc_max - src_graph.arcs);
  int arc_num = (int)(src_graph.arc_last - src_graph.arcs);
  arcs = (arc*) malloc(arc_num_max*sizeof(arc));
  if (!arcs) { if (error_function) (*error_function)("Not enough memory!"); exit(1); }
  memcpy(arcs, src_graph.arcs, arc_num_max*sizeof(arc));

  arc_last = arcs + arc_num;
  arc_max = arcs + arc_num_max;

  signed long long nodes_offset = (char*)nodes - (char*)src_graph.nodes;
  signed long long arcs_offset = (char*)arcs - (char*)src_graph.arcs;

  node *i;
  arc *a;
  // deep copy of nodes
  for (i=nodes; i<node_last; ++i) {
    if (i->next)
      i->next = (node*) ((char*)i->next + nodes_offset);
    if (i->first && i->first != ORPHAN && i->first != TERMINAL)
      i->first = (arc*) ((char*)i->first + arcs_offset);
    if (i->parent && i->parent != ORPHAN && i->parent != TERMINAL)
      i->parent = (arc*) ((char*)i->parent + arcs_offset);
  }
  // deep copy of arcs
  for (a=arcs; a<arc_last; ++a) {
    if (a->head)
      a->head = (node*) ((char*)a->head + nodes_offset);
    if (a->sister && a->sister != ORPHAN && a->sister != TERMINAL)
      a->sister = (arc*) ((char*)a->sister + arcs_offset);
    if (a->next && a->next != ORPHAN && a->next != TERMINAL)
      a->next = (arc*) ((char*)a->next + arcs_offset);
  }

  // deep copy queues
  queue_first[0] = src_graph.queue_first[0];
  queue_first[1] = src_graph.queue_first[1];
  queue_last[0] = src_graph.queue_last[0];
  queue_last[1] = src_graph.queue_last[1];
  if (queue_first[0])
    queue_first[0] = (node*) ((char*)queue_first[0] + nodes_offset);
  if (queue_first[1])
    queue_first[1] = (node*) ((char*)queue_first[1] + nodes_offset);
  if (queue_last[0])
    queue_last[0] = (node*) ((char*)queue_last[0] + nodes_offset);
  if (queue_last[1])
    queue_last[1] = (node*) ((char*)queue_last[1] + nodes_offset);

  orphan_first = NULL;
  orphan_last = NULL;
  nodeptr_block = NULL;

  // deep copy the nodeptr_block used for maintaining orphan lists
  if (src_graph.nodeptr_block) {
    nodeptr_block = new DBlock<nodeptr>(NODEPTR_BLOCK_SIZE, error_function);

    nodeptr *new_np, *prv_np = NULL;
    for (nodeptr *np=src_graph.orphan_first; np; np=np->next) {
      new_np = nodeptr_block -> New();
      new_np->next = NULL;
      new_np->ptr = (node*) ((char*)np->ptr + nodes_offset);
      if (!orphan_first)
        orphan_first = new_np;
      if (!prv_np)
        prv_np->next = new_np;
      prv_np = new_np;
    }
    orphan_last = prv_np;
  }

  changed_list = NULL;

  // deep copy the changed_list
  if (src_graph.changed_list) {
    node_id* ptr;
    for (ptr=src_graph.changed_list->ScanFirst(); ptr;
         ptr=src_graph.changed_list->ScanNext()) {
      node_id i = *ptr;
      node_id* new_cl_ptr = changed_list->New();
      *new_cl_ptr = i;
    }
  }
}

#endif