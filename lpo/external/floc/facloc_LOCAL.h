// facloc_LOCAL.h
#ifndef _FACLOC_LOCAL
#define _FACLOC_LOCAL

/* Local Search algorithms - solves the problem with Local Search or Tabu Search

   UFLP-call interface:
   --------------------
   Please provide the following arrays:	

   open_cost   = double[facilities];
   cost_matrix = double[facilities*cities];

   All data non-negative. The connection cost from city j to facility i
   is denoted in position cost_matrix[(i*cities) + j]
  
   connected   = int[cities];
   
   is the solution. connected[i] and contains the index of the facility 
   city i is connected to in the best solution found.


   Algorithms and datastructures were described in

   P. Van Hentenryck and L. Michel.
   A simple tabu search for warehouse location.
   Technical Report, Brown University, 2001.

   V. Arya, N. Garg, R. Khandekar, A. Meyerson, K. Munagala and V. Pandit.
   Local search heuristics for $k$-median and facility location problems.
   ACM Symposium on Theory of Computing, pages 21-29, 2001.

*/
  
// Solves the problem with scaled opening costs by sqrt(2) 
bool UNCAP_FACILITY_LOCATION_SCALED_LOCAL(const double *open_cost,
	       const double *cost_matrix,
	       const int facilities,
	       const int cities,
	             int *connected,
	             double& cost);

// Local Search
bool UNCAP_FACILITY_LOCATION_LOCAL(const double *open_cost,
	       const double *cost_matrix,
	       const int facilities,
	       const int cities,
	             int *connected,
	             double& cost);

// Tabu Seach with 250 failed runs maximum
bool UNCAP_FACILITY_LOCATION_TABU250(const double *open_cost, 
	       const double *cost_matrix, 
               const int facilities, 
	       const int cities, 
                     int *connected, 
		     double& cost);

// Tabu Search
bool UNCAP_FACILITY_LOCATION_TABU(const double *open_cost, 
	       const double *cost_matrix, 
               const int facilities, 
	       const int cities, 
                     int *connected, 
		     double& cost);
#endif
