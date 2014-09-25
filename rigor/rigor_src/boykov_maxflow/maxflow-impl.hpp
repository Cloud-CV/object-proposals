// Edited by:
//  @authors:     Ahmad Humayun
//  @contact:     ahumayun@cc.gatech.edu
//  @affiliation: Georgia Institute of Technology
//  @date:        Fall 2013 - Summer 2014

/* maxflow.cpp */

#ifndef __MAXFLOWIMPL_HPP__
#define __MAXFLOWIMPL_HPP__

#include <stdio.h>
#include <iostream>
#include <boost/format.hpp>

#include "graph.h"

using boost::format;


/*
	special constants for node->parent. Duplicated in graph.cpp, both should match!
*/
#define TERMINAL ( (arc *) 1 )		/* to terminal */
#define ORPHAN   ( (arc *) 2 )		/* orphan */


#define INFINITE_D ((int)(((unsigned)-1)/2))		/* infinite distance to the terminal */



/*
	Returns the next active node.
	If it is connected to the sink, it stays in the list,
	otherwise it is removed from the list
*/
template <typename captype, typename tcaptype, typename flowtype> 
	inline typename Graph<captype,tcaptype,flowtype>::node* Graph<captype,tcaptype,flowtype>::next_active()
{
	node *i;

	while ( 1 )
	{
	  // if the queue 0 is empty, swap with queue 1
		if (!(i=queue_first[0]))
		{
			queue_first[0] = i = queue_first[1];
			queue_last[0]  = queue_last[1];
			queue_first[1] = NULL;
			queue_last[1]  = NULL;
			if (!i) return NULL;
		}

		/* remove it from the active list */
		if (i->next == i) queue_first[0] = queue_last[0] = NULL;
		else              queue_first[0] = i -> next;
		i -> next = NULL;

		/* a node in the list is active iff it has a parent */
		if (i->parent) return i;
	}
}

/***********************************************************************/

template <typename captype, typename tcaptype, typename flowtype> 
	inline void Graph<captype,tcaptype,flowtype>::set_orphan_front(node *i)
{
	nodeptr *np;
	i -> parent = ORPHAN;
	//i -> src_origin_idx = INVALID_SRC_ID;
	np = nodeptr_block -> New();
	np -> ptr = i;
	np -> next = orphan_first;
	orphan_first = np;
}

template <typename captype, typename tcaptype, typename flowtype> 
	inline void Graph<captype,tcaptype,flowtype>::set_orphan_rear(node *i)
{
	nodeptr *np;
	i -> parent = ORPHAN;
	//i -> src_origin_idx = INVALID_SRC_ID;
	np = nodeptr_block -> New();
	np -> ptr = i;
	if (orphan_last) orphan_last -> next = np;
	else             orphan_first        = np;
	orphan_last = np;
	np -> next = NULL;
}

/***********************************************************************/

template <typename captype, typename tcaptype, typename flowtype> 
	inline void Graph<captype,tcaptype,flowtype>::add_to_changed_list(node *i)
{
	if (changed_list && !i->is_in_changed_list)
	{
		node_id* ptr = changed_list->New();
		*ptr = (node_id)(i - nodes);
		i->is_in_changed_list = true;
	}
}

/************************************************process_sink_orphan***********************/

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::maxflow_init()
{
	node *i;

	queue_first[0] = queue_last[0] = NULL;
	queue_first[1] = queue_last[1] = NULL;
	orphan_first = NULL;

	TIME = 0;

	for (i=nodes; i<node_last; i++)
	{
		i -> next = NULL;
		i -> is_marked = 0;
		i -> is_in_changed_list = 0;
		i -> TS = TIME;
		if (i->tr_cap > 0)
		{
			/* i is connected to the source */
			i -> is_sink = 0;
			i -> parent = TERMINAL;
			set_active(i);
			i -> DIST = 1;
			if (i -> src_origin_idx == INVALID_SRC_ID)
			  i -> src_origin_idx = 0;
		}
		else if (i->tr_cap < 0)
		{
			/* i is connected to the sink */
			i -> is_sink = 1;
			i -> parent = TERMINAL;
			set_active(i);
			i -> DIST = 1;
			i -> src_origin_idx = INVALID_SRC_ID;
		}
		else
		{
			/* i is free */
			i -> parent = NULL;
			i -> src_origin_idx = INVALID_SRC_ID;
		}
	}
}

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::maxflow_reuse_trees_init()
{
	node* i;
	node* j;
	// the queue would be checked from the second list
	node* queue = queue_first[1];
	arc* a;
	nodeptr* np;

	// vacate all queues because they will rebuilt
	queue_first[0] = queue_last[0] = NULL;
	queue_first[1] = queue_last[1] = NULL;
	orphan_first = orphan_last = NULL;

	TIME ++;

	// iterate over the whole active list (coming from the second list)
	while ((i=queue))
	{
	  // de-queue the first node
		queue = i->next;
		// if node was last in queue, set queue to NULL
		if (queue == i) queue = NULL;
		// disconnect the current node from the queue
		i->next = NULL;
		i->is_marked = 0;
		// add node to the second queue
		set_active(i);

		// in case node has no residual capacity to src/sink
		if (i->tr_cap == 0)
		{
		  // if the node has a parent, then set the node to orphan
		  // - this is a simple thing to do because you don't need to go up on the
		  //   tree to see if the root still belongs to the same src/sink this node
		  //   belongs to
			if (i->parent) set_orphan_rear(i);
			continue;
		}

		if (i->tr_cap > 0)
		{
	    // if node could be connected to src

		  // if node has no parent (neither is terminal or orphan) OR is is in the
		  // sink side of the cut
			if (!i->parent || i->is_sink)
			{
			  // assign node to src (because have residual cap to src)
				i->is_sink = 0;
				if (curr_src_origin_idx != INVALID_SRC_ID)
				  i->src_origin_idx = curr_src_origin_idx;
				// iterate over all the edges connected to this node
				for (a=i->first; a; a=a->next)
				{
					j = a->head;
					// if not already marked (only marked by mark_node() - used to
					// indicate which parts of the tree have changed)
					if (!j->is_marked)
					{
					  // if neighboring node j is child of i, with edge going to i
					  //  (as a sink tree), then set to orphan
						if (j->parent == a->sister) set_orphan_rear(j);
						// if neighboring node is in sink and there is residual capacity to
						//  push flow, then set to active
						if (j->parent && j->is_sink && a->r_cap > 0) set_active(j);
					}
				}
				add_to_changed_list(i);
			}
		}
		else
		{
		  // if node could be connected to sink

      // if node has no parent (neither is terminal or orphan) OR is in the
      // src side of the cut
			if (!i->parent || !i->is_sink)
			{
			  // assign node to sink (because have residual cap to sink)
				i->is_sink = 1;
				i->src_origin_idx = INVALID_SRC_ID;
				// iterate over all the edges connected to this node
				for (a=i->first; a; a=a->next)
				{
					j = a->head;
					// if not already marked
					if (!j->is_marked)
					{
					  // if neighboring node j is child of i, with edge going to i
					  //  (as a sink tree), then set to orphan
						if (j->parent == a->sister) set_orphan_rear(j);
						// if neighboring node is in src and there is residual capacity to
            //  push flow, then set to active
						if (j->parent && !j->is_sink && a->sister->r_cap > 0) set_active(j);
					}
				}
				add_to_changed_list(i);
			}
		}
		// if set to src/sink - directly connect to terminal
		i -> parent = TERMINAL;
		i -> TS = TIME;
		i -> DIST = 1;
	}

	//test_consistency();

	/* adoption */
	// iterate over all orphans and try to adopt them into trees
	while ((np=orphan_first))
	{
		orphan_first = np -> next;
		i = np -> ptr;
		nodeptr_block -> Delete(np);
		if (!orphan_first) orphan_last = NULL;
		if (i->is_sink) process_sink_orphan(i);
		else            process_source_orphan(i);
	}
	/* adoption end */

	//test_consistency();
}

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::augment(arc *middle_arc)
{
	node *i;
	arc *a;
	tcaptype bottleneck;

	/* 1. Finding bottleneck capacity */
	/* 1a - the source tree */
	bottleneck = middle_arc -> r_cap;
	for (i=middle_arc->sister->head; ; i=a->head)
	{
		a = i -> parent;
		if (a == TERMINAL) break;
		if (bottleneck > a->sister->r_cap) bottleneck = a -> sister -> r_cap;
		//gassert(i->src_origin_idx != INVALID_SRC_ID, "src_origin_idx needs to be src");

		//if (i->parent->head->parent != TERMINAL && i->parent->head->parent != ORPHAN && i->parent->head->parent != NULL) {
		//  gassert(i->parent->head->parent->head != i, "circular");
		//}
	}
	if (bottleneck > i->tr_cap) bottleneck = i -> tr_cap;
	/* 1b - the sink tree */
	for (i=middle_arc->head; ; i=a->head)
	{
		a = i -> parent;
		if (a == TERMINAL) break;
		if (bottleneck > a->r_cap) bottleneck = a -> r_cap;

		//gassert(i->src_origin_idx == INVALID_SRC_ID, "src_origin_idx needs to be sink");
	}
	if (bottleneck > - i->tr_cap) bottleneck = - i -> tr_cap;
	//gassert(bottleneck > 0, "bottleneck should be positive");

	/* 2. Augmenting */
	/* 2a - the source tree */
	middle_arc -> sister -> r_cap += bottleneck;
	middle_arc -> r_cap -= bottleneck;
	for (i=middle_arc->sister->head; ; i=a->head)
	{
		a = i -> parent;
		if (a == TERMINAL) break;
		a -> r_cap += bottleneck;
		a -> sister -> r_cap -= bottleneck;
		if (!a->sister->r_cap)
		{
			set_orphan_front(i); // add i to the beginning of the adoption list
		}
	}
	i -> tr_cap -= bottleneck;
	if (!i->tr_cap)
	{
		set_orphan_front(i); // add i to the beginning of the adoption list
	}
	/* 2b - the sink tree */
	for (i=middle_arc->head; ; i=a->head)
	{
		a = i -> parent;
		if (a == TERMINAL) break;
		a -> sister -> r_cap += bottleneck;
		a -> r_cap -= bottleneck;
		if (!a->r_cap)
		{
			set_orphan_front(i); // add i to the beginning of the adoption list
		}
	}
	i -> tr_cap += bottleneck;
	if (!i->tr_cap)
	{
		set_orphan_front(i); // add i to the beginning of the adoption list
	}

	++num_augmentations;

	flow += bottleneck;
}

/***********************************************************************/

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::process_source_orphan(node *i)
{
	node *j;
	arc *a0, *a0_min = NULL, *a;
	int d, d_min = INFINITE_D;

	if (i->tr_cap > 0) {
	  // if there is direct residual capacity to the src
	  a0_min = TERMINAL;
	  d_min = 0;
	} else {
	  // set node free if it has some children (i.e. don't attempt to adopt)
	  bool has_children = false;
    for (a0=i->first; a0; a0=a0->next) {
      j = a0 -> head;
      if (j->parent && j->parent != TERMINAL && j->parent != ORPHAN) {
        if (j->parent->head == i) {
          has_children = true;
          break;
        }
      }
    }

    /* trying to find a new parent */
    for (a0=i->first; !has_children && a0; a0=a0->next) {
      // if the reverse arc has residual capacity, it can possibly adopt
      if (a0->sister->r_cap)
      {
        // j now is the node the arc points to
        j = a0 -> head;
        // if j is in src
        if (!j->is_sink && (a=j->parent) &&
            j->src_origin_idx == i->src_origin_idx)
        {
          /*
          // if the arc points to something that is a child
          if (j->parent != TERMINAL && j->parent != ORPHAN) {
            if (j->parent->head == i)
              break;
          }*/
          // checking the origin of j
          d = 0;
          while ( 1 )
          {
            // if the timing is up to date, find the distance terminal
            if (j->TS == TIME)
            {
              d += j -> DIST;
              break;
            }
            // if the time stamp was old, then keep moving up on the tree
            a = j -> parent;
            d ++;
            if (a==TERMINAL)
            {
              j -> TS = TIME;
              j -> DIST = 1;
              break;
            }
            if (a==ORPHAN) { d = INFINITE_D; break; }
            j = a -> head;
          }
          if (d<INFINITE_D) // if j is on a path at some distance from src
          {
            if (d<d_min)
            {
              a0_min = a0;
              d_min = d;
            }
            /* set marks along the path */
            for (j=a0->head; j->TS!=TIME; j=j->parent->head)
            {
              j -> TS = TIME;
              j -> DIST = d --;
            }
          }
        }
      }
    }
	}

	if (i->parent = a0_min)
	{
		i -> TS = TIME;
		i -> DIST = d_min + 1;

		++num_adoptions;
	}
	else
	{
	  i -> src_origin_idx = INVALID_SRC_ID;

		/* no parent is found */
		add_to_changed_list(i);

		/* make sure now its source id is set to default null value */
		i->src_origin_idx = INVALID_SRC_ID;

		/* process neighbors */
		for (a0=i->first; a0; a0=a0->next)
		{
			j = a0 -> head;
			if (!j->is_sink && (a=j->parent))
			{
				if (a0->sister->r_cap) set_active(j);
				if (a!=TERMINAL && a!=ORPHAN && a->head==i)
				{
					set_orphan_rear(j); // add j to the end of the adoption list
				}
			}
		}
	}
}

template <typename captype, typename tcaptype, typename flowtype> 
	void Graph<captype,tcaptype,flowtype>::process_sink_orphan(node *i)
{
	node *j;
	arc *a0, *a0_min = NULL, *a;
	int d, d_min = INFINITE_D;

  if (i->tr_cap < 0) {
    // if there is direct residual capacity to the sink
    a0_min = TERMINAL;
    d_min = 0;
  } else {
    // set node free if it has some children (i.e. don't attempt to adopt)
    bool has_children = false;
    for (a0=i->first; a0; a0=a0->next) {
      j = a0 -> head;
      if (j->parent && j->parent != TERMINAL && j->parent != ORPHAN) {
        if (j->parent->head == i) {
          has_children = true;
          break;
        }
      }
    }

    /* trying to find a new parent */
    for (a0=i->first; !has_children && a0; a0=a0->next) {
      // if the arc has residual capacity, it can possibly adopt
      if (a0->r_cap)
      {
        // j now is the node the arc points to
        j = a0 -> head;
        if (j->is_sink && (a=j->parent))
        {
          /*
          // if the arc points to something that is a child
          if (j->parent != TERMINAL && j->parent != ORPHAN) {
            if (j->parent->head == i)
              break;
          }*/
          /* checking the origin of j */
          d = 0;
          while ( 1 )
          {
            // if the timing is up to date, find the distance terminal
            if (j->TS == TIME)
            {
              d += j -> DIST;
              break;
            }
            // if the time stamp was old, then keep moving up on the tree
            a = j -> parent;
            d ++;
            if (a==TERMINAL)
            {
              j -> TS = TIME;
              j -> DIST = 1;
              break;
            }
            if (a==ORPHAN) { d = INFINITE_D; break; }
            j = a -> head;
          }
          if (d<INFINITE_D) // if j is on a path at some distance from sink
          {
            if (d<d_min)
            {
              a0_min = a0;
              d_min = d;
            }
            /* set marks along the path */
            for (j=a0->head; j->TS!=TIME; j=j->parent->head)
            {
              j -> TS = TIME;
              j -> DIST = d --;
            }
          }
        }
      }
    }
	}

	if (i->parent = a0_min)
	{
		i -> TS = TIME;
		i -> DIST = d_min + 1;

		++num_adoptions;
	}
	else
	{
	  i -> src_origin_idx = INVALID_SRC_ID;

		/* no parent is found */
		add_to_changed_list(i);

		/* process neighbors */
		for (a0=i->first; a0; a0=a0->next)
		{
			j = a0 -> head;
			if (j->is_sink && (a=j->parent))
			{
				if (a0->r_cap) set_active(j);
				if (a!=TERMINAL && a!=ORPHAN && a->head==i)
				{
					set_orphan_rear(j); // add j to the end of the adoption list
				}
			}
		}
	}
}

/***********************************************************************/

template <typename captype, typename tcaptype, typename flowtype> 
	flowtype Graph<captype,tcaptype,flowtype>::maxflow(bool reuse_trees, Block<node_id>* _changed_list, bool run_init_func)
{
	node *i, *j, *current_node = NULL;
	arc *a;
	nodeptr *np, *np_next;

	if (!nodeptr_block)
	{
		nodeptr_block = new DBlock<nodeptr>(NODEPTR_BLOCK_SIZE, error_function);
	}

	// initialize the counters
	num_growths = 0;
	num_augmentations = 0;
	num_adoptions = 0;

	changed_list = _changed_list;
	if (maxflow_iteration == 0 && reuse_trees) { if (error_function) (*error_function)("reuse_trees cannot be used in the first call to maxflow()!"); exit(1); }
	if (changed_list && !reuse_trees) { if (error_function) (*error_function)("changed_list cannot be used without reuse_trees!"); exit(1); }

	if (run_init_func) {
    if (reuse_trees) maxflow_reuse_trees_init();
    else             maxflow_init();
	}

	// main loop
	while ( 1 )
	{
		// test_consistency(current_node);

		if ((i=current_node))
		{
			i -> next = NULL; /* remove active flag */
			if (!i->parent) i = NULL;
		}
		if (!i)
		{
		  /* get the next active node (and remove from the active list)
		   * - when no active nodes remaining, the algorithm ends
		   */
			if (!(i = next_active())) break;
		}

		/* growth */
		if (!i->is_sink)
		{
			/* grow source tree */
		  /* iterate over all the edges coming out of this active node */
			for (a=i->first; a; a=a->next) {
			  /* if the edge has a residual capacity, it can potentially become part of the S tree */
        if (a->r_cap)
        {
          j = a -> head;
          /* in case the terminus node of the arc is free, add to S tree (and
           * set newly added node to active) */
          if (!j->parent)
          {
            j -> is_sink = 0;
            j -> parent = a -> sister;
            j -> TS = i -> TS;
            j -> DIST = i -> DIST + 1;
            j -> src_origin_idx = i ->src_origin_idx;
            set_active(j);
            add_to_changed_list(j);
            ++num_growths;
          }
          /* if arc connects S tree to T tree, an augmenting path has been found */
          else if (j->is_sink)
            break;
          else if (j->TS <= i->TS &&
                   j->DIST > i->DIST &&
                   j -> src_origin_idx == i -> src_origin_idx)
          {
            /* heuristic - trying to make the distance from j to the source shorter */
            j -> parent = a -> sister;
            j -> TS = i -> TS;
            j -> DIST = i -> DIST + 1;
          }
        }
			}
		}
		else
		{
			/* grow sink tree */
		  /* iterate over all the edges coming out of this active node */
			for (a=i->first; a; a=a->next) {
			  /* if the reverse edge has a residual capacity, it can potentially become part of the T tree */
        if (a->sister->r_cap)
        {
          j = a -> head;
          /* in case the terminus node of the arc is free, add to T tree (and
           * set newly added node to active) */
          if (!j->parent)
          {
            j -> is_sink = 1;
            j -> parent = a -> sister;
            j -> TS = i -> TS;
            j -> DIST = i -> DIST + 1;
            set_active(j);
            add_to_changed_list(j);
            ++num_growths;
          }
          /* if arc connects T tree to S tree, an augmenting path has been found */
          else if (!j->is_sink) {
            /* set arc to the reverse edge (which we checked has residual capacity) */
            a = a -> sister;
            break;
          }
          else if (j->TS <= i->TS &&
                   j->DIST > i->DIST)
          {
            /* heuristic - trying to make the distance from j to the sink shorter */
            j -> parent = a -> sister;
            j -> TS = i -> TS;
            j -> DIST = i -> DIST + 1;
          }
        }
			}
		}

		TIME ++;

		/* if we found an augmenting path */
		if (a)
		{
			i -> next = i; /* set active flag */
			current_node = i;

			/* augmentation */
			augment(a);
			/* augmentation end */

			/* adoption - adopt all orphans or set them free */
			while ((np=orphan_first))
			{
				np_next = np -> next;
				np -> next = NULL;

				while ((np=orphan_first))
				{
					orphan_first = np -> next;
					i = np -> ptr;
					nodeptr_block -> Delete(np);
					if (!orphan_first) orphan_last = NULL;
					if (i->is_sink) process_sink_orphan(i);
					else            process_source_orphan(i);
				}

				orphan_first = np_next;
			}
			/* adoption end */
		}
		else current_node = NULL;
	}

	// test_consistency();

	if (!reuse_trees || (maxflow_iteration % 64) == 0)
	{
		delete nodeptr_block; 
		nodeptr_block = NULL; 
	}

	maxflow_iteration ++;
	return flow;
}

/***********************************************************************/


template <typename captype, typename tcaptype, typename flowtype>
	void Graph<captype,tcaptype,flowtype>::test_consistency(node* current_node) const
{
  std::cout << "Checking tree consistency" << std::endl;

	node *i;
	arc *a;
	int r;
	int num1 = 0, num2 = 0;

	// test whether all nodes i with i->next!=NULL are indeed in the queue
	for (i=nodes; i<node_last; i++)
	{
		if (i->next || i==current_node) num1 ++;
	}
	for (r=0; r<3; r++)
	{
		i = (r == 2) ? current_node : queue_first[r];
		if (i)
		for ( ; ; i=i->next)
		{
			num2 ++;
			if (i->next == i)
			{
			  // check if the last node is also indicated by queue_last
				if (r<2) gassert(i == queue_last[r], "i != queue_last[r]");
				else gassert(i == current_node, "i != current_node");
				break;
			}
		}
	}
	gassert(num1 == num2, "num1 != num2");

	for (i=nodes; i<node_last; i++)
	{
    node_id nid = (node_id)(i - nodes);

		// test whether all edges in search trees are non-saturated
    if (i->parent == NULL) {
      // if node is free
		  gassert(i->tr_cap == 0,
		          (format("free node %d cannot have any tr cap") % nid).str());
		  gassert(i->src_origin_idx == INVALID_SRC_ID,
		          (format("free node %d cannot have src id") % nid).str());
		}
		else if (i->parent == ORPHAN) {}
		else if (i->parent == TERMINAL)
		{
		  // if node is terminal, it should have appropriate residual
		  if (!i->is_sink) {
			  gassert(i->tr_cap > 0,
			          (format("src node %d has <= 0 tr cap") % nid).str());
			  gassert(i->src_origin_idx != INVALID_SRC_ID,
			          (format("src node %d INVALID_SRC_ID") % nid).str());
		  } else {
			  gassert(i->tr_cap < 0,
			          (format("sink node %d has >= 0 tr cap") % nid).str());
        gassert(i->src_origin_idx == INVALID_SRC_ID,
                (format("sink node %d not INVALID_SRC_ID") % nid).str());
		  }
		}
		else
		{
		  node_id pid = (node_id)(i - nodes);

		  // if the node has a parent
			if (!i->is_sink) {
        gassert(i->tr_cap >= 0,
                (format("src node %d has < 0 tr cap") % nid).str());
        gassert(i->parent->head->src_origin_idx == i->src_origin_idx,
                (format("src node %d doesn't have same src id as parent %d (%d %d)") % nid % (node_id)(i->parent->head-nodes) % i->src_origin_idx % i->parent->head->src_origin_idx).str());
			  gassert(i->parent->sister->r_cap > 0,
			          (format("src node %d connected to the parent %d with <= 0 residual cap arc") % nid % pid).str());
			} else {
			  gassert(i->tr_cap <= 0,
                (format("sink node %d has > 0 tr cap") % nid).str());
        gassert(i->src_origin_idx == INVALID_SRC_ID,
                (format("sink node %d doesn't have INVALID_SRC_ID") % nid).str());
			  gassert(i->parent->r_cap > 0,
			          (format("sink node %d connected to the parent %d with <= 0 residual cap arc") % nid % pid).str());
			}
		}

		// test whether passive nodes in search trees have neighbors in
		// a different tree through non-saturated edges
		if (i->parent && !i->next)
		{
			if (!i->is_sink)
			{
				for (a=i->first; a; a=a->next)
				{
					if (a->r_cap > 0) {
					  gassert(a->head->parent != NULL && a->head->parent != ORPHAN,
					          "src passive node cannot have a remaining residual "
					          "connection to a null or an orphan node");
            gassert(!a->head->is_sink, "src passive node cannot have a "
                    "remaining residual connection to a sink node");
					}
				}
			}
			else
			{
				for (a=i->first; a; a=a->next)
				{
					if (a->sister->r_cap > 0) {
					  gassert(a->head->parent != NULL && a->head->parent != ORPHAN,
					          "sink passive node cannot have a remaining residual "
					          "connection to a null or an orphan node");
            gassert(a->head->is_sink, "sink passive node cannot have a "
                    "remaining residual connection to a src node");
					}
				}
			}
		}

		// test marking invariants
		if (i->parent && i->parent!=ORPHAN && i->parent!=TERMINAL)
		{
		  gassert(i->TS <= i->parent->head->TS, "i->TS > i->parent->head->TS");

			if (i->TS == i->parent->head->TS)
			  gassert(i->DIST > i->parent->head->DIST,
			          (format("%d->DIST <= (PARENT)%d->DIST")
			              % (node_id)(i-nodes) % (node_id)(i->parent->head-nodes)).str());
		}
	}
}

#endif