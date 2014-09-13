#include <mex.h>
#include <stdio.h>
/*#include <sys/time.h>
#include <sys/resource.h>*/
#include <stdlib.h>
#include <string.h>

/*#define BREAKPOINTS 1*/
typedef long long int llint;

/* the function is not used */
/*double 
timer (void)
{
  struct rusage r;

  getrusage(0, &r);
  return (double) (r.ru_utime.tv_sec + r.ru_utime.tv_usec / (double)1000000);
}
 */

struct node;

typedef struct arc 
{
	struct node *from;
	struct node *to;
	int flow;
	int capacity;
	int direction;
	int *capacities;
} Arc;

typedef struct node 
{
	int visited;
	int numAdjacent;
	int number;
	int label;
	int excess;
	struct node *parent;
	struct node *childList;
	struct node *nextScan;
	int numOutOfTree;
	Arc **outOfTree;
	int nextArc;
	Arc *arcToParent;
	struct node *next;
	struct node *prev;
	int breakpoint;
} Node;


typedef struct root 
{
	Node *start;
	Node *end;
} Root;

/*---------------  Global variables ------------------*/
static int numNodes = 0;
static int numArcs = 0;
static int source = 0;
static int sink = 0;
static int numParams = 0;

static int highestStrongLabel = 1;

static Node *adjacencyList = NULL;
static Root *strongRoots = NULL;
static int *labelCount = NULL;
static Arc *arcList = NULL;
/*-----------------------------------------------------*/

#ifdef STATS
static llint numPushes = 0;
static int numMergers = 0;
static int numRelabels = 0;
static int numGaps = 0;
static llint numArcScans = 0;
#endif

static void
initializeNode (Node *nd, const int n)
{
	nd->label = 0;
	nd->excess = 0;
	nd->parent = NULL;
	nd->childList = NULL;
	nd->nextScan = NULL;
	nd->nextArc = 0;
	nd->numOutOfTree = 0;
	nd->arcToParent = NULL;
	nd->next = NULL;
	nd->prev = NULL;
	nd->visited = 0;
	nd->numAdjacent = 0;
	nd->number = n;
	nd->outOfTree = NULL;
	nd->breakpoint = (numParams+1);
}

static void
initializeRoot (Root *rt) 
{
	rt->start = (Node *) malloc (sizeof(Node));
	rt->end = (Node *) malloc (sizeof(Node));

	if ((rt->start == NULL) || (rt->end == NULL))
	{
		mexPrintf ("%s Line %d: Out of memory\n", __FILE__, __LINE__);
		exit (1);
	}

	initializeNode (rt->start, 0);
	initializeNode (rt->end, 0);

	rt->start->next = rt->end;
	rt->end->prev = rt->start;
}


static void
freeRoot (Root *rt) 
{
	free(rt->start);
	rt->start = NULL;

	free(rt->end);
	rt->end = NULL;
}

static void
liftAll (Node *rootNode, const int theparam) 
{
	Node *temp, *current=rootNode;

	current->nextScan = current->childList;

	-- labelCount[current->label];
	current->label = numNodes;	
	current->breakpoint = (theparam+1);

	for ( ; (current); current = current->parent)
	{
		while (current->nextScan) 
		{
			temp = current->nextScan;
			current->nextScan = current->nextScan->next;
			current = temp;
			current->nextScan = current->childList;

			-- labelCount[current->label];
			current->label = numNodes;
			current->breakpoint = (theparam+1);	
		}
	}
}

static void
addToStrongBucket (Node *newRoot, Node *rootEnd) 
{
	newRoot->next = rootEnd;
	newRoot->prev = rootEnd->prev;
	rootEnd->prev = newRoot;
	newRoot->prev->next = newRoot;
}

static void
createOutOfTree (Node *nd)
{
	if (nd->numAdjacent)
	{
		if ((nd->outOfTree = (Arc **) malloc (nd->numAdjacent * sizeof (Arc *))) == NULL)
		{
			mexPrintf ("%s Line %d: Out of memory\n", __FILE__, __LINE__);
			exit (1);
		}
	}
}

static void
initializeArc (Arc *ac)
{
	ac->from = NULL;
	ac->to = NULL;
	ac->capacity = 0;
	ac->flow = 0;
	ac->direction = 1;
	ac->capacities = NULL;
}

static void
addOutOfTreeNode (Node *n, Arc *out) 
{
	n->outOfTree[n->numOutOfTree] = out;
	++ n->numOutOfTree;
}


static void
simpleInitialization (void) 
{
	int i, size;
	Arc *tempArc;

	size = adjacencyList[source-1].numOutOfTree;
	for (i=0; i<size; ++i) 
	{
		tempArc = adjacencyList[source-1].outOfTree[i];
		tempArc->flow = tempArc->capacity;
		tempArc->to->excess += tempArc->capacity;
	}

	size = adjacencyList[sink-1].numOutOfTree;
	for (i=0; i<size; ++i)
	{
		tempArc = adjacencyList[sink-1].outOfTree[i];
		tempArc->flow = tempArc->capacity;
		tempArc->from->excess -= tempArc->capacity;
	}

	adjacencyList[source-1].excess = 0;
	adjacencyList[sink-1].excess = 0;

	for (i=0; i<numNodes; ++i) 
	{
		if (adjacencyList[i].excess > 0) 
		{
		    adjacencyList[i].label = 1;
			++ labelCount[1];

			addToStrongBucket (&adjacencyList[i], strongRoots[1].end);
		}
	}

	adjacencyList[source-1].label = numNodes;
	adjacencyList[source-1].breakpoint = 0;
	adjacencyList[sink-1].label = 0;
	adjacencyList[sink-1].breakpoint = (numParams+2);
	labelCount[0] = (numNodes - 2) - labelCount[1];
}

/*static inline int  addRelationship (Node *newParent, Node *child) */
int  addRelationship (Node *newParent, Node *child) 
{
	child->parent = newParent;
	child->next = newParent->childList;
	newParent->childList = child;

	return 0;
}


/*static inline void breakRelationship (Node *oldParent, Node *child) */
void breakRelationship (Node *oldParent, Node *child)
{
	Node *current;

	child->parent = NULL;

	if (oldParent->childList == child) 
	{
		oldParent->childList = child->next;
		child->next = NULL;
		return;
	}

	for (current = oldParent->childList; (current->next != child); current = current->next);

	current->next = child->next;
	child->next = NULL;
}

static void
merge (Node *parent, Node *child, Arc *newArc) 
{
	Arc *oldArc;
	Node *current = child, *oldParent, *newParent = parent;

#ifdef STATS
	++ numMergers;
#endif

	while (current->parent) 
	{
		oldArc = current->arcToParent;
		current->arcToParent = newArc;
		oldParent = current->parent;
		breakRelationship (oldParent, current);
		addRelationship (newParent, current);
		newParent = current;
		current = oldParent;
		newArc = oldArc;
		newArc->direction = 1 - newArc->direction;
	}

	current->arcToParent = newArc;
	addRelationship (newParent, current);
}


/*static inline void pushUpward (Arc *currentArc, Node *child, Node *parent, const int resCap) */
void pushUpward (Arc *currentArc, Node *child, Node *parent, const int resCap) 
{
#ifdef STATS
	++ numPushes;
#endif

	if (resCap >= child->excess) 
	{
		parent->excess += child->excess;
		currentArc->flow += child->excess;
		child->excess = 0;
		return;
	}

	currentArc->direction = 0;
	parent->excess += resCap;
	child->excess -= resCap;
	currentArc->flow = currentArc->capacity;
	parent->outOfTree[parent->numOutOfTree] = currentArc;
	++ parent->numOutOfTree;
	breakRelationship (parent, child);

	addToStrongBucket (child, strongRoots[child->label].end);
}


/*static inline void pushDownward (Arc *currentArc, Node *child, Node *parent, int flow) */
void pushDownward (Arc *currentArc, Node *child, Node *parent, int flow)
{
#ifdef STATS
	++ numPushes;
#endif

	if (flow >= child->excess) 
	{
		parent->excess += child->excess;
		currentArc->flow -= child->excess;
		child->excess = 0;
		return;
	}

	currentArc->direction = 1;
	child->excess -= flow;
	parent->excess += flow;
	currentArc->flow = 0;
	parent->outOfTree[parent->numOutOfTree] = currentArc;
	++ parent->numOutOfTree;
	breakRelationship (parent, child);

	addToStrongBucket (child, strongRoots[child->label].end);
}

static void
pushExcess (Node *strongRoot) 
{
	Node *current, *parent;
	Arc *arcToParent;

	for (current = strongRoot; (current->excess && current->parent); current = parent) 
	{
		parent = current->parent;
		arcToParent = current->arcToParent;
		if (arcToParent->direction)
		{
			pushUpward (arcToParent, current, parent, (arcToParent->capacity - arcToParent->flow)); 
		}
		else
		{
			pushDownward (arcToParent, current, parent, arcToParent->flow); 
		}
	}

	if (current->excess > 0) 
	{
		if (!current->next)
		{
			addToStrongBucket (current, strongRoots[current->label].end);
		}
	}
}


static Arc *
findWeakNode (Node *strongNode, Node **weakNode) 
{
	int i, size;
	Arc *out;

	size = strongNode->numOutOfTree;

	for (i=strongNode->nextArc; i<size; ++i) 
	{

#ifdef STATS
		++ numArcScans;
#endif

		if (strongNode->outOfTree[i]->to->label == (highestStrongLabel-1)) 
		{
			strongNode->nextArc = i;
			out = strongNode->outOfTree[i];
			(*weakNode) = out->to;
			-- strongNode->numOutOfTree;
			strongNode->outOfTree[i] = strongNode->outOfTree[strongNode->numOutOfTree];
			return (out);
		}
		else if (strongNode->outOfTree[i]->from->label == (highestStrongLabel-1)) 
		{
			strongNode->nextArc = i;
			out = strongNode->outOfTree[i];
			(*weakNode) = out->from;
			-- strongNode->numOutOfTree;
			strongNode->outOfTree[i] = strongNode->outOfTree[strongNode->numOutOfTree];
			return (out);
		}
	}

	strongNode->nextArc = strongNode->numOutOfTree;

	return NULL;
}


static void
checkChildren (Node *curNode) 
{
	for ( ; (curNode->nextScan); curNode->nextScan = curNode->nextScan->next)
	{
		if (curNode->nextScan->label == curNode->label)
		{
			return;
		}
		
	}	

	-- labelCount[curNode->label];
	++	curNode->label;
	++ labelCount[curNode->label];

#ifdef STATS
	++ numRelabels;
#endif

	curNode->nextArc = 0;
}

static void
processRoot (Node *strongRoot) 
{
	Node *temp, *strongNode = strongRoot, *weakNode;
	Arc *out;

	strongRoot->nextScan = strongRoot->childList;

	if ((out = findWeakNode (strongRoot, &weakNode)))
	{
		merge (weakNode, strongNode, out);
		pushExcess (strongRoot);
		return;
	}

	checkChildren (strongRoot);
	
	while (strongNode)
	{
		while (strongNode->nextScan) 
		{
			temp = strongNode->nextScan;
			strongNode->nextScan = strongNode->nextScan->next;
			strongNode = temp;
			strongNode->nextScan = strongNode->childList;

			if ((out = findWeakNode (strongNode, &weakNode)))
			{
				merge (weakNode, strongNode, out);
				pushExcess (strongRoot);
				return;
			}

			checkChildren (strongNode);
		}

		if ((strongNode = strongNode->parent))
		{
			checkChildren (strongNode);
		}
	}

	addToStrongBucket (strongRoot, strongRoots[strongRoot->label].end);

	++ highestStrongLabel;
}

static Node *
getHighestStrongRoot (const int theparam) 
{
	int i;
	Node *strongRoot;

	for (i=highestStrongLabel; i>0; --i) 
	{
		if (strongRoots[i].start->next != strongRoots[i].end)  
		{
			highestStrongLabel = i;
			if (labelCount[i-1]) 
			{
				strongRoot = strongRoots[i].start->next;
				strongRoot->next->prev = strongRoot->prev;
				strongRoot->prev->next = strongRoot->next;
				strongRoot->next = NULL;
				return strongRoot;				
			}

			while (strongRoots[i].start->next != strongRoots[i].end) 
			{

#ifdef STATS
				++ numGaps;
#endif
				strongRoot = strongRoots[i].start->next;
				strongRoot->next->prev = strongRoot->prev;
				strongRoot->prev->next = strongRoot->next;
				liftAll (strongRoot, theparam);
			}
		}
	}

	if (strongRoots[0].start->next == strongRoots[0].end) 
	{
		return NULL;
	}

	while (strongRoots[0].start->next != strongRoots[0].end) 
	{
		strongRoot = strongRoots[0].start->next;
		strongRoot->next->prev = strongRoot->prev;
		strongRoot->prev->next = strongRoot->next;

		strongRoot->label = 1;
		-- labelCount[0];
		++ labelCount[1];

#ifdef STATS
		++ numRelabels;
#endif

		addToStrongBucket (strongRoot, strongRoots[strongRoot->label].end);
	}	

	highestStrongLabel = 1;

	strongRoot = strongRoots[1].start->next;
	strongRoot->next->prev = strongRoot->prev;
	strongRoot->prev->next = strongRoot->next;
	strongRoot->next = NULL;

	return strongRoot;	
}

static void
updateCapacities (const int theparam)
{
	int i, size;
	int delta;
	Arc *tempArc;
	/*Node *tempNode;*/

	size = adjacencyList[source-1].numOutOfTree;
	for (i=0; i<size; ++i) 
	{
		tempArc = adjacencyList[source-1].outOfTree[i];
		delta = (tempArc->capacities[theparam] - tempArc->capacity);
		if (delta < 0)
		{
			mexPrintf ("c Error on source-adjacent arc (%d, %d): capacity decreases by %d at parameter %d.\n",
				tempArc->from->number,
				tempArc->to->number,
				(-delta),
				(theparam+1));
			exit(0);
		}

		tempArc->capacity += delta;
		tempArc->flow += delta;
		tempArc->to->excess += delta;

		if ((tempArc->to->label < numNodes) && (tempArc->to->excess > 0))
		{
			pushExcess (tempArc->to);
		}
	}

	size = adjacencyList[sink-1].numOutOfTree;
	for (i=0; i<size; ++i)
	{
		tempArc = adjacencyList[sink-1].outOfTree[i];
		delta = (tempArc->capacities[theparam] - tempArc->capacity);
		if (delta > 0)
		{
			mexPrintf ("c Error on sink-adjacent arc (%d, %d): capacity %d increases to %d at parameter %d.\n",
				tempArc->from->number,
				tempArc->to->number,
				tempArc->capacity,
				tempArc->capacities[theparam],
				(theparam+1));
			exit(0);
		}

		tempArc->capacity += delta;
		tempArc->flow += delta;
		tempArc->from->excess -= delta;

		if ((tempArc->from->label < numNodes) && (tempArc->from->excess > 0))
		{
			pushExcess (tempArc->from);
		}
	}

	highestStrongLabel = (numNodes-1);
}

static int
computeMinCut (void)
{
	int i, mincut=0;

	for (i=0; i<numArcs; ++i) 
	{
		if ((arcList[i].from->label >= numNodes) && (arcList[i].to->label < numNodes))
		{
			mincut += arcList[i].capacity;
		}
	}
	return mincut;
}

static void
pseudoflowPhase1 (void) 
{
	Node *strongRoot;
	int theparam = 0;
	/*double thetime;*/

	/*thetime = timer ();*/
	while ((strongRoot = getHighestStrongRoot (theparam)))  
	{ 
		processRoot (strongRoot);
	}
	/*mexPrintf ("c Finished solving parameter %d\nc Flow: %d\nc Elapsed time: %.3f\n", 
		(theparam+1),
		computeMinCut (),
		(timer () - thetime));*/

	for (theparam=1; theparam < numParams; ++ theparam)
	{
		updateCapacities (theparam);
#ifdef PROGRESS
		mexPrintf ("c Finished updating capacities and excesses.\n");
		fflush (stdout);
#endif
		while ((strongRoot = getHighestStrongRoot (theparam)))  
		{ 
			processRoot (strongRoot);
		}
        /*
		mexPrintf ("c Finished parameter: %d\nc Flow: %d\nc Elapsed time: %.3f\n", 
			(theparam+1),
			computeMinCut (),
			(timer () - thetime));*/
	}
}

static void
checkOptimality (void) 
{
	int i, check = 1;
	llint mincut = 0, *excess; 

	excess = (llint *) malloc (numNodes * sizeof (llint));
	if (!excess)
	{
		mexPrintf ("%s Line %d: Out of memory\n", __FILE__, __LINE__);
		exit (1);
	}

	for (i=0; i<numNodes; ++i)
	{
		excess[i] = 0;
	}

	for (i=0; i<numArcs; ++i) 
	{
		if ((arcList[i].from->label >= numNodes) && (arcList[i].to->label < numNodes))
		{
			mincut += arcList[i].capacity;
		}

		if ((arcList[i].flow > arcList[i].capacity) || (arcList[i].flow < 0)) 
		{
			check = 0;
			mexPrintf("c Capacity constraint violated on arc (%d, %d)\n", 
				arcList[i].from->number,
				arcList[i].to->number);
		}
		excess[arcList[i].from->number - 1] -= arcList[i].flow;
		excess[arcList[i].to->number - 1] += arcList[i].flow;
	}

	for (i=0; i<numNodes; i++) 
	{
		if ((i != (source-1)) && (i != (sink-1))) 
		{
			if (excess[i]) 
			{
				check = 0;
				mexPrintf ("c Flow balance constraint violated in node %d. Excess = %lld\n", 
					i+1,
					excess[i]);
			}
		}
	}

	if (check)
	{
		mexPrintf ("c\nc Solution checks as feasible.\n");
	}

	check = 1;

	if (excess[sink-1] != mincut) 
	{
		check = 0;
		mexPrintf("c Flow is not optimal - max flow does not equal min cut!\nc\n");
	}

	if (check) 
	{
		mexPrintf ("c\nc Solution checks as optimal.\nc \n");
		mexPrintf ("s Max Flow            : %lld\n", mincut);
	}

	free (excess);
	excess = NULL;
}


static void
quickSort (Arc **arr, const int first, const int last)
{
	int i, j, left=first, right=last, x1, x2, x3, mid, pivot, pivotval;
	Arc *swap;

	if ((right-left) <= 5)
	{/* Bubble sort if 5 elements or less*/
		for (i=right; (i>left); --i)
		{
			swap = NULL;
			for (j=left; j<i; ++j)
			{
				if (arr[j]->flow < arr[j+1]->flow)
				{
					swap = arr[j];
					arr[j] = arr[j+1];
					arr[j+1] = swap;
				}
			}

			if (!swap)
			{
				return;
			}
		}

		return;
	}

	mid = (first+last)/2;

	x1 = arr[first]->flow; 
	x2 = arr[mid]->flow; 
	x3 = arr[last]->flow;

	pivot = mid;
	
	if (x1 <= x2)
	{
		if (x2 > x3)
		{
			pivot = left;

			if (x1 <= x3)
			{
				pivot = right;
			}
		}
	}
	else
	{
		if (x2 <= x3)
		{
			pivot = right;

			if (x1 <= x3)
			{
				pivot = left;
			}
		}
	}

	pivotval = arr[pivot]->flow;

	swap = arr[first];
	arr[first] = arr[pivot];
	arr[pivot] = swap;

	left = (first+1);

	while (left < right)
	{
		if (arr[left]->flow < pivotval)
		{
			swap = arr[left];
			arr[left] = arr[right];
			arr[right] = swap;
			-- right;
		}
		else
		{
			++ left;
		}
	}

	swap = arr[first];
	arr[first] = arr[left];
	arr[left] = swap;

	if (first < (left-1))
	{
		quickSort (arr, first, (left-1));
	}
	
	if ((left+1) < last)
	{
		quickSort (arr, (left+1), last);
	}
}

static void
sort (Node * current)
{
	if (current->numOutOfTree > 1)
	{
		quickSort (current->outOfTree, 0, (current->numOutOfTree-1));
	}
}

static void
minisort (Node *current) 
{
	Arc *temp = current->outOfTree[current->nextArc];
	int i, size = current->numOutOfTree, tempflow = temp->flow;

	for(i=current->nextArc+1; ((i<size) && (tempflow < current->outOfTree[i]->flow)); ++i)
	{
		current->outOfTree[i-1] = current->outOfTree[i];
	}
	current->outOfTree[i-1] = temp;
}

static void
decompose (Node *excessNode, const int source, int *iteration) 
{
	Node *current = excessNode;
	Arc *tempArc;
	int bottleneck = excessNode->excess;

	for ( ;(current->number != source) && (current->visited < (*iteration)); 
				current = tempArc->from)
	{
		current->visited = (*iteration);
		tempArc = current->outOfTree[current->nextArc];

		if (tempArc->flow < bottleneck)
		{
			bottleneck = tempArc->flow;
		}
	}

	if (current->number == source) 
	{
		excessNode->excess -= bottleneck;
		current = excessNode;

		while (current->number != source) 
		{
			tempArc = current->outOfTree[current->nextArc];
			tempArc->flow -= bottleneck;

			if (tempArc->flow) 
			{
				minisort(current);
			}
			else 
			{
				++ current->nextArc;
			}
			current = tempArc->from;
		}
		return;
	}

	++ (*iteration);

	bottleneck = current->outOfTree[current->nextArc]->flow;

	while (current->visited < (*iteration))
	{
		current->visited = (*iteration);
		tempArc = current->outOfTree[current->nextArc];

		if (tempArc->flow < bottleneck)
		{
			bottleneck = tempArc->flow;
		}
		current = tempArc->from;
	}	
	
	++ (*iteration);

	while (current->visited < (*iteration))
	{
		current->visited = (*iteration);

		tempArc = current->outOfTree[current->nextArc];
		tempArc->flow -= bottleneck;

		if (tempArc->flow) 
		{
			minisort(current);
			current = tempArc->from;
		}
		else 
		{
			++ current->nextArc;
			current = tempArc->from;
		}
	}
}

static void
recoverFlow (void)
{
	int i, j, iteration = 1;
	Arc *tempArc;
	Node *tempNode;

	for (i=0; i<adjacencyList[sink-1].numOutOfTree; ++i) 
	{
		tempArc = adjacencyList[sink-1].outOfTree[i];
		if (tempArc->from->excess < 0) 
		{
			tempArc->flow -= (int) (-1*tempArc->from->excess); 
			tempArc->from->excess = 0;
		}	
	}

	for (i=0; i<adjacencyList[source-1].numOutOfTree; ++i) 
	{
		tempArc = adjacencyList[source-1].outOfTree[i];
		addOutOfTreeNode (tempArc->to, tempArc);
	}

	adjacencyList[source-1].excess = 0;
	adjacencyList[sink-1].excess = 0;

	for (i=0; i<numNodes; ++i) 
	{
		tempNode = &adjacencyList[i];

		if ((i == (source-1)) || (i == (sink-1)))
		{
			continue;
		}

		if (tempNode->label >= numNodes) 
		{
			tempNode->nextArc = 0;
			if ((tempNode->parent) && (tempNode->arcToParent->flow))
			{
				addOutOfTreeNode (tempNode->arcToParent->to, tempNode->arcToParent);
			}

			for (j=0; j<tempNode->numOutOfTree; ++j) 
			{
				if (!tempNode->outOfTree[j]->flow) 
				{
					-- tempNode->numOutOfTree;
					tempNode->outOfTree[j] = tempNode->outOfTree[tempNode->numOutOfTree];
					-- j;
				}
			}

			sort(tempNode);
		}
	}

	for (i=0; i<numNodes; ++i) 
	{
		tempNode = &adjacencyList[i];
		while (tempNode->excess > 0) 
		{
			++ iteration;
			decompose(tempNode, source, &iteration);
		}
	}
}


static void
displayBreakpoints (void)
{
	int i;
	for (i=0; i<numNodes; ++i)
	{
		mexPrintf ("n %d %d\n", (i+1), adjacencyList[i].breakpoint);
	}
}

static void
freeMemory (void)
{
	int i;

	for (i=0; i<numNodes; ++i)
	{
		freeRoot (&strongRoots[i]);
	}

	free (strongRoots);

	for (i=0; i<numNodes; ++i)
	{
        
		if (adjacencyList[i].outOfTree)
		{
			free (adjacencyList[i].outOfTree);
		}
	}

	free (adjacencyList);

	free (labelCount);

    for(i=0; i<numArcs;i++){
        free(arcList[i].capacities);
    }
	free (arcList);
}

/* 0 arg -- numNodes
 *  1 arg -- numArcs
 *  2 arg -- numParams
 *  3 arg -- s 
 *  4 arg -- t
 *  5 arg -- graph edges and weights
 *  6 arg -- lambda edges and weights
 */
void jlGetPars(int nrhs,const mxArray *prhs[]) {
	int i, capacity, from, to, first=0, j;
	Arc *ac = NULL;
    double *normal_edges, *special_edges;

    long int n_edges;
    long int n_cols;
    
    /*double thetime;
	thetime = timer ();*/
    
    numNodes =mxGetScalar(prhs[0]);
    numArcs = mxGetScalar(prhs[1]);
    numParams = mxGetScalar(prhs[2]);    
    source = mxGetScalar(prhs[3]);
    sink = mxGetScalar(prhs[4]);
    /*sscanf(line, "%c %s %d %d %d", &ch, word, &numNodes, &numArcs, &numParams);*/
    /*
    mexPrintf("numNodes: %d, numArcs: %d, numParams: %d, s: %d, t: %d\n", \
            numNodes, \
            numArcs, \
            numParams, \
            source, \
            sink);*/
    if(0 > source || 0 > sink){
        mexErrMsgTxt("negative source or sink node ids");
    }
            
            
    if ((adjacencyList = (Node *) malloc(numNodes * sizeof (Node))) == NULL) {
        mexPrintf("%s, %d: Could not allocate memory.\n", __FILE__, __LINE__);
        exit(1);
    }
    
    if ((strongRoots = (Root *) malloc(numNodes * sizeof (Root))) == NULL) {
        mexPrintf("%s, %d: Could not allocate memory.\n", __FILE__, __LINE__);
        exit(1);
    }
    
    if ((labelCount = (int *) malloc(numNodes * sizeof (int))) == NULL) {
        mexPrintf("%s, %d: Could not allocate memory.\n", __FILE__, __LINE__);
        exit(1);
    }
    
    if ((arcList = (Arc *) malloc(numArcs * sizeof (Arc))) == NULL) {
        mexPrintf("%s, %d: Could not allocate memory.\n", __FILE__, __LINE__);
        exit(1);
    }
    
    /*for (i=0; i<numNodes; ++i) {*/
    for (i=0; i<numNodes; ++i) {
        initializeRoot(&strongRoots[i]);
        initializeNode(&adjacencyList[i], (i+1));
        labelCount[i] = 0;
    }
    
    for (i=0; i<numArcs; ++i) {
        initializeArc(&arcList[i]);
    }

    /* normal edges */
    normal_edges = mxGetPr(prhs[5]);
    n_edges = mxGetM(prhs[5]);
    n_cols = mxGetN(prhs[5]);
    
    for (i=0; i<n_edges;++i) {
        from = (int) normal_edges[i];
        to = (int) normal_edges[n_edges + i];

        ac = &arcList[first];

        ac->from = &adjacencyList[from-1];
        ac->to = &adjacencyList[to-1];
 
        if ((ac->capacities = (int *) malloc(sizeof (int))) == NULL) {
            mexPrintf("%s Line %d: Out of memory\n", __FILE__, __LINE__);
            return;
        }
        
        ac->capacities[0] = normal_edges[n_edges*2+i];
        ac->capacity = ac->capacities[0];

        ++ first;

        ++ ac->from->numAdjacent;
        ++ ac->to->numAdjacent;
        /*mexPrintf("%d %d %d\n", from, to, ac->capacity);*/
	}
    /*
    mexPrintf("Finished reading normal edges\n");
    */
    
    /* now the special edges */
    special_edges = mxGetPr(prhs[6]);
    n_edges = mxGetM(prhs[6]);
    n_cols = mxGetN(prhs[6]);
    
    for (i=0; i<n_edges;i++) {
        from = (int) special_edges[i];
        to = (int) special_edges[n_edges + i];
        
        ac = &arcList[first];
        
        ac->from = &adjacencyList[from-1];
        ac->to = &adjacencyList[to-1];
 
        if ((ac->capacities = (int *) malloc (numParams * sizeof (int))) == NULL)
        {
            printf ("%s Line %d: Out of memory\n", __FILE__, __LINE__);
            exit (1);
        }
        for (j=0; j<numParams; ++j)
        {
            ac->capacities[j] = 0;
        }
        
        for(j=0; j<numParams;j++) {
            ac->capacities[j] = special_edges[n_edges*(2+j) + i];            
        }
        
        ac->capacity = ac->capacities[0];

        ++ first;

        ++ ac->from->numAdjacent;
        ++ ac->to->numAdjacent;
        /*mexPrintf("%d %d %d\n", from, to, ac->capacity);*/
	}
    /*
    mexPrintf("Finished reading special edges\n");
    */
    /* this is done after reading everything */
	for (i=0; i<numNodes; ++i) 
	{
		createOutOfTree (&adjacencyList[i]);
	}

	for (i=0; i<numArcs; i++) 
	{
		to = arcList[i].to->number;
		from = arcList[i].from->number;
		capacity = arcList[i].capacity;

		if (!((source == to) || (sink == from) || (from == to))) 
		{
			if ((source == from) && (to == sink)) 
			{
				arcList[i].flow = capacity;
			}
			else if (from == source)
			{
				addOutOfTreeNode (&adjacencyList[from-1], &arcList[i]);
			}
			else if (to == sink)
			{
				addOutOfTreeNode (&adjacencyList[to-1], &arcList[i]);
			}
			else
			{
				addOutOfTreeNode (&adjacencyList[from-1], &arcList[i]);
			}
		}
	}
    /*mexPrintf("time for reading: %f\n", (timer () - thetime));*/
}

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    unsigned int *out_cuts; 
    int i;
	
	if(nrhs<6) {
        mexErrMsgTxt("Number of inputs should be  6!");
    }
    
    if(nlhs<1) {
        mexErrMsgTxt("Number of outputs should be  1!");
    }
	
	/*mexPrintf ("c Pseudoflow algorithm for parametric min cut (version 1.0)\n");*/
    jlGetPars(nrhs, prhs);

/*
#ifdef PROGRESS
	mexPrintf ("c Finished reading file.\n"); fflush (stdout);
#endif
*/
	simpleInitialization ();
	highestStrongLabel = 1; /* required, if not there's a nasty problem (don't know exactly why) */
/*
#ifdef PROGRESS
	mexPrintf ("c Finished initialization.\n"); fflush (stdout);
#endif
*/
	pseudoflowPhase1 ();

/*
#ifdef PROGRESS
	mexPrintf ("c Finished phase 1.\n"); fflush (stdout);
#endif
*/
/*
#ifdef RECOVER_FLOW
	recoverFlow();
	checkOptimality ();
#endif
*/

    plhs[0] = mxCreateNumericMatrix(numNodes, 2, mxUINT32_CLASS,mxREAL);
    out_cuts = (unsigned int*) mxGetData(plhs[0]);

    for (i=0; i<numNodes; i++)	{
        out_cuts[i] = i+1;
        out_cuts[i+numNodes] = adjacencyList[i].breakpoint;		
	}

	freeMemory ();
}
