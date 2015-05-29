// facloc_JMS.h
#ifndef _FACLOC_JMS
#define _FACLOC_JMS

/* JMS- and MYZ-approximation algorithms
   -------------------------------------

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
   
   K. Jain, M. Mahdian and A. Sabieri.
   A new greedy approach for facility location problems.
   STOC 2002, 2002.

   
   M. Mahdian, Y. Ye and J. Zhang.
   Improved approximation algorithms for metric facility location problems.
   In Proceedings of the 5th APPROX Conference, to appear, 2002.
*/


// JMS-algorithm 
bool UNCAP_FACILITY_LOCATION_JMS(const double *open_cost,
	       const double *cost_matrix,
	       const int facilities,
	       const int cities,
		     int *connected, 
	             double& cost);

// MYZ-algorithm 
bool UNCAP_FACILITY_LOCATION_MYZ(const double *open_cost,
	       const double *cost_matrix,
	       const int facilities,
	       const int cities,
	             int *connected,
	             double& cost);

#endif
