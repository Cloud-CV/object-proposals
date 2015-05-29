// basic_calls.h
#ifndef _FACLOC_BASIC
#define _FACLOC_BASIC

#define MIN(a,b) ((a<b)?a:b)
#define MAX(a,b) ((a>b)?a:b)

#include <fstream>

double numberize(std::ifstream& input, int &precise);

void mergesort(const double *cost_matrix, 
	       int *temp,
	       const int left, 
	       const int right, 
	       int *order);

double time();

bool test_metric(const double *cost_matrix, 
		 const int facilities, 
		 const int cities, 
		 int &facil, 
		 int &city, 
		 int &length, 
		 int *way);

#endif
