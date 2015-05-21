#include<iostream>
#include<cstdlib>
#include<cmath>

#include"basic_calls.h"

/* JMS and MYZ
   -----------

As the JMS-algorithm is a subroutine of MYZ, we implemented it in the way that it delivers
a little more information (the switch-savings-array) for the MYZ-algorithm. For calling
JMS directly, we added a routine that corresponds to the standard interface.
*/


// JMS Algorithm call that delivers the opened and switch-savings arrays
bool UNCAP_FACILITY_LOCATION_JMS(const double *open_cost, const double *cost_matrix, double *switch_savings, bool *opened,
				 const int facilities, const int cities, int *connected, double& cost) 
{
  // Algorithm: Jain, Mahdian, Sabieri - A new greedy approach
  // for facility location problems - STOC 02, 2002

  const int edges = facilities * cities;

  int    a, b, cnt,                        
         facil, facilbest, city,                      
         unconnected;                      // Number of unconnected facilities
  int    tights[facilities];               // Tight connections to a facility
  double next_cost, c,                     
         t;                                
  double exp_opentime[facilities],         // Expected opening time of a facility
         tightcons[facilities];            // Connection cost of tight connections to a facility
  bool   changed;

  // Pointer
  int *order = new int [edges];            // An array of indices for cost_matrix
  bool *visited = new bool [edges];        // Indicated visited edges
  
  unconnected = cities;
  cost = 0;

  // Init of arrays
  for (a = 0; a < facilities; a++) {
    for (b = 0; b < cities; b++) {
      order[a*cities + b] = (a*cities) + b;
      visited[a*cities + b] = false;
      connected[b] = -1;
    }
    tightcons[a] = 0;
    switch_savings[a] = 0;
    opened[a] = false;
    tights[a] = 0;
  }
   
  // Sorting the indices in order to have 
  // cost_matrix[order[0]] <= cost_matrix[order[1]] <= ... <= cost_matrix[order[edges-1]]
  int *temp = new int [edges];
  mergesort(cost_matrix, temp, 0, edges-1, order);
  delete[] temp;

  cnt = 0;   // edgecounter;
  next_cost = cost_matrix[order[0]];
  facilbest = -1;
  changed = false;

  /* This is the main loop of the algorithm. Every time we take the edge with the next higher connection
     cost and see, whether it has to be tight - the city has to be connected to the facility. Then we check,
     whether the costs of a facility is paid and it can be opened. Afterwards we check, whether one or more
     other facilities can be opened before proceeding to the next edge. When all cities are connected or 
     no edges and facilities are left, the loop terminates. */

  while ((unconnected > 0) && (cnt < edges)) {  

    // This is the actual 'time' - the cost of the current edge
    t = next_cost;
    facil = order[cnt] / cities;
    city = order[cnt] % cities;
    
    // here we determine the 'time' of the next edge
    next_cost = (cnt < (edges-1)) ? cost_matrix[order[cnt+1]] : HUGE;
    
    // If the city is still unconnected...
    if (connected[city] == -1) {
      // ...update the arrays.
      tights[facil]++;
      tightcons[facil] += t;

      // If furthermore the current connection is to an opened facility...
      if (opened[facil]) {	

	// ...connect the city to the facility...
        connected[city] = facil;
	unconnected--;
        
        facilbest = -1;
        changed = false;
	// ...and remove the entry in tight for all tight connections from this city to unopened facilities
	// and update the switch_savings
	for (a = 0; a < facilities; a++)
	  if (!opened[a]) {

	    c = cost_matrix[(a*cities) + city];
	    if (visited[(a*cities) + city]) { 
	      tights[a]--;
	      tightcons[a] -= c;
	    }
	    switch_savings[a] += MAX(t-c,0);

	    // Adjust expected opening time
	    if (tights[a] > 0) {
	      exp_opentime[a] = (double) (open_cost[a] + tightcons[a] - switch_savings[a]) / tights[a];
	      if ((!changed) || (exp_opentime[a] <= exp_opentime[facilbest])) {
		facilbest = a;
		changed = true;
	      }
	    } // end if tights > 0

	  } // end if
      } // end if opened

      else {
	// Adjust expected opening time of facil
	a = facil;
	exp_opentime[a] = (double) (open_cost[a] + tightcons[a] - switch_savings[a]) / tights[a];
	if ((!changed) || (exp_opentime[a] <= exp_opentime[facilbest])) {
	  facilbest = a;
	  changed = true;
	}
      } // end else
    } // end if connected

    // We now have completed the tasks regarding this edge.
    visited[order[cnt]] = true;      

    // If there is one facility, we open it... 
    while ((changed) && (unconnected > 0) && (exp_opentime[facilbest] <= next_cost)) {

      facil = facilbest;
      t = exp_opentime[facil];
      opened[facil] = true;
      for (b = 0; b < cities; b++) { 
	// We reconnect all cities already connected to other facilities, if they can be
	// connected for cheaper cost to this new facility
	
	if (connected[b] != -1) {
	  c = cost_matrix[(connected[b] * cities) + b];
	  
	  if (c > cost_matrix[(facil * cities) + b]) {  
	    
	    connected[b] = facil;
	    // We remove the switch_savings
	    for (a = 0; a < facilities; a++)
	      if (!opened[a]) {
		switch_savings[a] -= MAX(c-cost_matrix[(a*cities)+b], 0);
		switch_savings[a] += MAX(cost_matrix[(facil*cities) + b]-cost_matrix[(a*cities)+b],0);
	      }
	    
	  }
	}
	else {
	  if (visited[(facil*cities) + b]) {
	    
	    // And we connect all unconnected cities to our new opened facility - 
	    // of course only if the connection is tight at this moment
	    
	    connected[b] = facil;
	    unconnected--;
	    // and update the arrays and switch_savings
	    for (a = 0; a < facilities; a++)
	      if (!opened[a]) {
		
		c = cost_matrix[(a*cities) + b];
		if (visited[(a*cities) + b]) { 
		  tights[a]--;
		  tightcons[a] -= c;
		}
		switch_savings[a] += MAX(cost_matrix[(facil*cities)+b]-c,0);
	      } // end if
	    
	    
	  } // end if visited
	} // end if b connected
      } // end for
      
      // Well, maybe after these swicthes we are able to open another facility	
      changed = false;
      facilbest = -1;

      for (a = 0; a < facilities; a++)
	if ((!opened[a]) && (tights[a] > 0)) {
	  // Calculate expected opening times...
	  exp_opentime[a] = (double) (open_cost[a] + tightcons[a] - switch_savings[a]) / tights[a];
	  if ((!changed) || (exp_opentime[a] <= exp_opentime[facilbest])) {
	    facilbest = a;
	    changed = true;
	  }
	} 
    } // end while changed

    // Proceed to the next edge
    cnt++;
  } // end main loop
  
  delete []order;
  delete []visited;

  // Solution correct ?
  if (unconnected > 0) return(false); 

  // Calculating cost
  for (a = 0; a < facilities; a++)
    if (opened[a]) cost += open_cost[a];
  for (b = 0; b < cities; b++) 
    if (connected[b] != -1) cost += cost_matrix[(connected[b] * cities) + b];
  return true;

} // end UNCAP_FACILITY_LOCATION_JMS - basic algorithm - if successful returns connected[cities] and cost.



//###############################################################



// Call of the JMS-algorithm
bool UNCAP_FACILITY_LOCATION_JMS(const double *open_cost, const double *cost_matrix, 
				 const int facilities, const int cities, int *connected, double &cost)
{
  double *switch_savings = new double [facilities];
  bool *opened = new bool [facilities];

  bool val = UNCAP_FACILITY_LOCATION_JMS(open_cost, cost_matrix, switch_savings, opened, facilities, cities, connected, cost);
  
  delete[] opened;
  delete[] switch_savings;
  
  return val;
}


//###############################################################


// MYZ-algorithm
bool UNCAP_FACILITY_LOCATION_MYZ(const double* open_cost, const double* cost_matrix, 
				 const int facilities, const int cities, int* connected, double& cost)
{ 

  // Algorithm: Mahdian, Ye, Zhang: Improved algorithms for the metric 
  // facility location problems, IPOC 02 - 2002

  const double delta = 1.504;
  
  bool    val = false;
  int     a, b, best_facil;
  double  best_quotient, bq, cob, cb, ca;

  double *adjusted_open_cost = new double [facilities];
  bool   *opened = new bool [facilities];
  double *switch_savings = new double [facilities];



  // At first we adjust the opening cost a little bit
  for (a = 0; a < facilities; a++) {
    opened[a] = false;
    adjusted_open_cost[a] = delta * open_cost[a];
  }

  // Then we run the JMS-algorithm

  // double rt = time();
  if (!UNCAP_FACILITY_LOCATION_JMS(adjusted_open_cost, cost_matrix, switch_savings, opened, facilities, cities, connected, cost)) 
    goto TERMINATE;
  // cout << "time for JMS: " << time()-rt << endl;

  best_quotient = 0; best_facil = -1;
  // Reconstructing the opened facilities
  for (a = 0; a < facilities; a++) {
    if (opened[a]) 
      switch_savings[a] = 0;
    else if ((bq = (((double) switch_savings[a] / open_cost[a])) - 1) > best_quotient) {
      best_quotient = bq;
      best_facil = a;
    }
  }
    
  // Re-adjusting: We repeatedly find the best quotient for all unopened facilities 
  while (best_facil != -1) {

    // If the best quotient is > 0, we open the corresponding facility.    
    opened[best_facil] = true;
    for (b = 0; b < cities; b++) {
      cob = cost_matrix[(connected[b]*cities) + b];
      cb = cost_matrix[(best_facil*cities) + b];

      if (cob > cb) { 
	for (a = 0; a < facilities; a++) 
	  if (!opened[a]) {
	    ca = cost_matrix[(a*cities) + b];
	    switch_savings[a] -= MAX(cob-ca,0);
	    switch_savings[a] += MAX(cb-ca,0);
	  }
	connected[b] = best_facil;
      }
    }

    switch_savings[best_facil] = 0;

    best_quotient = 0;
    best_facil = -1;

    for (a = 0; a < facilities; a++)
      if (!opened[a]) 
	if ((bq = (((double) switch_savings[a] / open_cost[a])) - 1) > best_quotient) {
	  best_quotient = bq;
	  best_facil = a;
	}	
  } // end while

  val = true;

  // Calculate cost -
  cost = 0;
  for (a = 0; a < facilities; a++) if (opened[a]) cost += open_cost[a];
  for (b = 0; b < cities; b++) cost += cost_matrix[(connected[b] * cities) + b];

 TERMINATE:
  delete[] adjusted_open_cost;
  delete[] opened;
  delete[] switch_savings;

  return (val);
} // UNCAP_FACILITY_LOCATION_MYZ - basic algorithm - if successful returns connected[cities] and cost
