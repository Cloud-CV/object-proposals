/*
#########################################################
#                                                       #
#  IBFSGraph -  Software for solving                    #
#               Maximum s-t Flow / Minimum s-t Cut      #
#               using the IBFS algorithm                #
#                                                       #
#  http://www.cs.tau.ac.il/~sagihed/ibfs/               #
#                                                       #
#  Haim Kaplan (haimk@cs.tau.ac.il)                     #
#  Sagi Hed (sagihed@post.tau.ac.il)                    #
#                                                       #
#########################################################

This software implements the IBFS (Incremental Breadth First Search) maximum flow algorithm from
	"Maximum flows by incremental breadth-first search"
	Andrew V. Goldberg, Sagi Hed, Haim Kaplan, Robert E. Tarjan, and Renato F. Werneck.
	In Proceedings of the 19th European conference on Algorithms, ESA'11, pages 457-468.
	ISBN 978-3-642-23718-8
	2011

Copyright Haim Kaplan (haimk@cs.tau.ac.il) and Sagi Hed (sagihed@post.tau.ac.il)

###########
# LICENSE #
###########
This software can be used for research purposes only.
If you use this software for research purposes, you should cite the aforementioned paper
in any resulting publication and appropriately credit it.

If you require another license, please contact the above.

*/


#ifndef _IBFS_H__
#define _IBFS_H__

#include <stdio.h>
#include <string.h>


#define IBTEST 0
#define IBSTATS 0
#define IBDEBUG(X) fprintf(stdout, X"\n"); fflush(stdout)
#define IB_ALTERNATE_SMART 1

#define IB_ORPHANS_END   ( (Node *) 1 )



class IBFSStats
{
public:
	IBFSStats()
	{
		int C = (IBSTATS ? 0 : -1);
		augs=C;
		growthS=C;
		growthT=C;
		orphans=C;
		growthArcs=C;
		pushes=C;
		orphanArcs1=C;
		orphanArcs2=C;
		orphanArcs3=C;
		if (IBSTATS) augLenMin = (1 << 30);
		else augLenMin=C;
		augLenMax=C;
	}
	void inline incAugs() {if (IBSTATS) augs++;}
	double inline getAugs() {return augs;}
	void inline incGrowthS() {if (IBSTATS) growthS++;}
	double inline getGrowthS() {return growthS;}
	void inline incGrowthT() {if (IBSTATS) growthT++;}
	double inline getGrowthT() {return growthT;}
	void inline incOrphans() {if (IBSTATS) orphans++;}
	double inline getOrphans() {return orphans;}
	void inline incGrowthArcs() {if (IBSTATS) growthArcs++;}
	double inline getGrowthArcs() {return growthArcs;}
	void inline incPushes() {if (IBSTATS) pushes++;}
	double inline getPushes() {return pushes;}
	void inline incOrphanArcs1() {if (IBSTATS) orphanArcs1++;}
	double inline getOrphanArcs1() {return orphanArcs1;}
	void inline incOrphanArcs2() {if (IBSTATS) orphanArcs2++;}
	double inline getOrphanArcs2() {return orphanArcs2;}
	void inline incOrphanArcs3() {if (IBSTATS) orphanArcs3++;}
	double inline getOrphanArcs3() {return orphanArcs3;}
	void inline addAugLen(int len) {
		if (IBSTATS) {
			if (len > augLenMax) augLenMax = len;
			if (len < augLenMin) augLenMin = len;
		}
	}
	int inline getAugLenMin() {return augLenMin;}
	int inline getAugLenMax() {return augLenMax;}

private:
	double augs;
	double growthS;
	double growthT;
	double orphans;
	double growthArcs;
	double pushes;
	double orphanArcs1;
	double orphanArcs2;
	double orphanArcs3;
	int augLenMin;
	int augLenMax;
};




class IBFSGraph
{
public:

	IBFSGraph();
	~IBFSGraph();
	void setVerbose(bool a_verbose) {
		verbose = a_verbose;
	}
	bool readFromFile(char *filename);
	bool readFromFileCompile(char *filename);
	void initSize(int numNodes, int numEdges);
	void addEdge(int nodeIndexFrom, int nodeIndexTo, int capacity, int reverseCapacity);
	void addNode(int nodeIndex, int capacityFromSource, int capacityToSink);
	void setCompactSlowInitMode(bool a_compactSlowInitMode) {
		compactSlowInitMode = a_compactSlowInitMode;
	}
	void initGraph();
	int computeMaxFlow();

	inline IBFSStats getStats() {
		return stats;
	}
	inline int getFlow() {
		return flow;
	}
	inline int getNumNodes() {
		return nodeEnd-nodes;
	}
	inline int getNumArcs() {
		return arcEnd-arcs;
	}
	bool isNodeOnSrcSide(int nodeIndex);

private:
	struct Node;
	struct Arc;

	struct Arc
	{
		Node*		head;
		Arc*		rev;
		int			isRevResidual :1;
		int			rCap :31;
	};

	class Node
	{
	public:
		int			lastAugTimestamp:31;
		int			isParentCurr:1;
		Arc			*firstArc;
		Arc			*parent;
		Node		*firstSon;
		Node		*nextPtr;
		int			label;	// label > 0: distance from s, label < 0: -distance from t
		int			excess;	 // excess > 0: capacity from s, excess < 0: -capacity to t
	};

	class ActiveList
	{
	public:
		inline ActiveList() {
			list = NULL;
			len = 0;
		}
		inline void init(int numNodes) {
			list = new Node*[numNodes];
			len = 0;
		}
		inline void free() {
			if (list != NULL) {
				delete list;
				list = NULL;
			}
		}
		inline void clear() {
			len = 0;
		}
		inline void add(Node* x) {
			list[len] = x;
			len++;
		}
		inline static void swapLists(ActiveList *a, ActiveList *b) {
			ActiveList tmp = (*a);
			(*a) = (*b);
			(*b) = tmp;
		}
		Node **list;
		int len;
	};

	class Buckets
	{
	public:
		inline Buckets() {
			buckets = NULL;
			prevPtrs = NULL;
			maxBucket = 0;
			nodes = NULL;
		}
		inline void init(Node *a_nodes, int numNodes) {
			nodes = a_nodes;
			buckets = new Node*[numNodes];
			memset(buckets, 0, sizeof(Node*)*numNodes);
			prevPtrs = new Node*[numNodes];
			memset(prevPtrs, 0, sizeof(Node*)*numNodes);
			maxBucket = 0;
		}
		inline void free() {
			if (buckets != NULL) {
				delete buckets;
				buckets = NULL;
			}
			if (prevPtrs != NULL) {
				delete prevPtrs;
				prevPtrs = NULL;
			}
		}
		template <bool sTree> inline void add(Node* x) {
			int bucket = (sTree ? (x->label) : (-x->label));
			if (buckets[bucket] == NULL || buckets[bucket] == IB_ORPHANS_END) {
				x->nextPtr = IB_ORPHANS_END;
			} else {
				x->nextPtr = buckets[bucket];
				prevPtrs[x->nextPtr-nodes] = x;
			}
			buckets[bucket] = x;
			if (bucket > maxBucket) maxBucket = bucket;
		}
		inline Node* popFront(int bucket) {
			Node *x = buckets[bucket];
			if (x == NULL || x == IB_ORPHANS_END) return NULL;
			buckets[bucket] = x->nextPtr;
			//x->nextOrphan = NULL;
			return x;
		}
		template <bool sTree> inline void remove(Node *x) {
			int bucket = (sTree ? (x->label) : (-x->label));
			if (buckets[bucket] == x) {
				buckets[bucket] = x->nextPtr;
			} else {
				prevPtrs[x-nodes]->nextPtr = x->nextPtr;
				if (x->nextPtr != IB_ORPHANS_END) prevPtrs[x->nextPtr-nodes] = prevPtrs[x-nodes];
			}
			//x->nextOrphan = NULL;
		}

		Node **buckets;
		Node **prevPtrs;
		int maxBucket;
		Node *nodes;
	};

	// members
	IBFSStats stats;
	Node	*nodes, *nodeEnd;
	Arc		*arcs, *arcEnd;
	int 	numNodes;
	int		flow;
	short 	augTimestamp;
	unsigned int uniqOrphansS, uniqOrphansT;
	Node* orphanFirst;
	Node* orphanLast;
	int topLevelS, topLevelT;
	ActiveList active0, activeS1, activeT1;
	Buckets orphanBuckets;
	bool verbose;

	bool readFromFile(char *filename, bool checkCompile);
	bool readCompiled(FILE *pFile);
	void augment(Arc *bridge);
	template<bool sTree> void augmentTree(Node *x, int bottleneck);
	template <bool sTree> void adoption();
	template <bool sTree> void adoption3Pass();
	template <bool dirS> void growth();


	//
	// Initialization
	//
	struct TmpEdge
	{
		Node*		head;
		Node*		tail;
		int			cap;
		int			revCap;
	};
	struct TmpArc
	{
		TmpArc		*rev;
		int			cap;
	};
	char	*memArcs;
	TmpEdge	*tmpEdges, *tmpEdgeLast;
	TmpArc	*tmpArcs;
	bool compactSlowInitMode;
	void initGraphFast();
	void initGraphCompact();

	//
	// Testing
	//
	void testTree();
	void testExit() {
		exit(1);
	}
	inline void testNode(Node *x) {
		if (IBTEST && x-nodes == -1) {
			IBDEBUG("*");
		}
	}
};





inline void IBFSGraph::addNode(int nodeIndex, int capacitySource, int capacitySink)
{
	int f = nodes[nodeIndex].excess;
	if (f > 0) {
		capacitySource += f;
	} else {
		capacitySink -= f;
	}
	if (capacitySource < capacitySink) {
		flow += capacitySource;
	} else {
		flow += capacitySink;
	}
	nodes[nodeIndex].excess = capacitySource - capacitySink;
}

inline void IBFSGraph::addEdge(int nodeIndexFrom, int nodeIndexTo, int capacity, int reverseCapacity)
{
	tmpEdgeLast->tail = nodes + nodeIndexFrom;
	tmpEdgeLast->head = nodes + nodeIndexTo;
	tmpEdgeLast->cap = capacity;
	tmpEdgeLast->revCap = reverseCapacity;
	tmpEdgeLast++;

	// use label as a temporary storage
	// to count the out degree of nodes
	nodes[nodeIndexFrom].label++;
	nodes[nodeIndexTo].label++;

	/*
	Arc *aFwd = arcLast;
	arcLast++;
	Arc *aRev = arcLast;
	arcLast++;

	Node* x = nodes + nodeIndexFrom;
	x->label++;
	Node* y = nodes + nodeIndexTo;
	y->label++;

	aRev->rev = aFwd;
	aFwd->rev = aRev;
	aFwd->rCap = capacity;
	aRev->rCap = reverseCapacity;
	aFwd->head = y;
	aRev->head = x;*/
}




inline bool IBFSGraph::isNodeOnSrcSide(int nodeIndex)
{
	if (nodes[nodeIndex].label == numNodes || nodes[nodeIndex].label == 0) {
		return activeT1.len == 0;
	}
	return (nodes[nodeIndex].label > 0);
}





#endif


