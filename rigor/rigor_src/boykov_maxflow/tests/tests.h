// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014


#ifndef _TESTS_TESTS_H_
#define _TESTS_TESTS_H_

#include <vector>
#include <iostream>

#include "../graph.h"
#include "examples.h"

/* The test is done by computing the cuts by increasing the unaries by 1 at
 * each max flow computation while reusing the trees - till exactly LAMBDA
 * is added to all unary values (after LAMBDA max flow iterations). We also
 * compute the solution of the graph by directly adding LAMBDA to all unaries
 * and then computing the cut. The test is passed if the solution to the
 * graph cut using the latter method is exactly the same from the last graph
 * cut from the iterative max-flows.
 */
void dynamicgraph_test();

void test_deepcopy();

void test_seedsolve();

#endif // _TESTS_TESTS_H_
