#include <cstdlib>
#include <cmath>
#include <iostream>
#include <algorithm>

#include "basic_calls.h"


#define BEST_START 0    // 0 means start with arbitrary solution
                        // 1 means start with solution, in which all facs are open and the cities
                        //   are connected to the best facility


/* Local Search algorithms for UFLP
-----------------------------------

The Local Search is devided in several subroutines. 
The Tabu Search is called by  UNCAP_FACILITY_LOCATION_TABU(...) or UNCAP_FACILITY_LOCATION_TABU250(...). The first
one uses 500 failed runs to cancel the search, the other one only 250. Tabu then sets up the data structures and finds
an initial solution with local_begin. In each iteration it calls gain_update, which updates the gains for the 
corresponding opening/closing actions. gain_update itself calls update_queue, which deletes or inserts facilities 
into the queues by downHeap and upHeap.
The Local Search is called by UNCAP_FACILITY_LOCATION_LOCAL(...) or UNCAP_FACILITY_LOCATION_LOCAL_SCALED(...).
The first one works on the original data, the other one scales up the opening costs by a factor of sqrt(2).
The Local Search inits a solution with local_begin and sets up the arrays. In each iteration it tries to
check simple flips like Tabu Search. When they fulfill the acception criterion, the solution and the gains
are updated with gain_update. gain_update calls update_queue, which updates the facilities in the queues with
upHeap and downHeap. When no solution is found, Local tries exchange steps and uses gain_update quite often
in these steps.
*/


// Standard Priority queues implemented with heaps
void downHeap(const double *cost_matrix, const int cities, const int city,
              int *queues, int *position_in_queues, const int start, const int given_parent, const int length,
              const bool output)
{
  int parent = given_parent;
  int newElt = queues[parent];
  int child = 2*parent-start; // left(parent)
  int childindex;
  while (child <= start+length) {  // parent has a child
    childindex = queues[child]*cities+city;
    if (child < start+length)    // has 2 children
      if (cost_matrix[queues[child+1]*cities + city] < cost_matrix[childindex])
        child++;       // right child is bigger
    childindex = queues[child]*cities+city;

    if (cost_matrix[newElt*cities + city] >= cost_matrix[childindex]) {
      queues[parent] = queues[child];

       position_in_queues[childindex] = parent;
       parent = child;
       child = 2*parent - start;
    }
    else break;
  }
  // ASSERT: child > N || newElt >= a[child]
  queues[parent] = newElt;
  position_in_queues[(newElt*cities)+city] = parent;
} // end downHeap


//###############################################################


void upHeap(const double *cost_matrix, const int cities, const int city,
            int *queues, int *position_in_queues, const int start, const int given_child)
{
  int child = given_child;
  int newElt = queues[child];
  int parent = start + (int) floor(((double) child-start) / 2);
  int indexElt = (newElt*cities)+city;

  double cost = cost_matrix[indexElt];

  while (parent > start) // child has a parent
    {
      if (cost_matrix[(queues[parent]*cities)+city] > cost) {
        queues[child] = queues[parent]; // move parent down
        position_in_queues[(queues[parent]*cities)+city] = child;

        child  = parent;
        parent = start + (int) floor(((double) child-start) / 2);
      }
      else break;
    }
  // ASSERT: child == 1 || newElt <= a[parent]
  queues[child] = newElt;
  position_in_queues[indexElt] = child;
} // end upHeap


//###############################################################


// Start-routine for updating the queues
void update_queue(const double *cost_matrix, const int facilities, const int cities, 
                  const int flip, const bool opened, int *queues, int *position_in_queues, 
                  const bool examcosts, int *affected, double *bestcosts, int &maxaffect)
{
  int flip_posi, a, parent, start, i, j, length;
  a = flip_posi = i = length = queues[0];
  double best_old[3], best_new[3];

  if (!opened) {
    // Facility closed
    for (j = 0; j < cities; j++) {
      start = j*facilities;

      // We exam facilities and check, whether the best two connections of city j 
      // are affected by the change in the solution

      if (examcosts) {
        // We only close a facility, when at least two were opened...
        best_old[0] = cost_matrix[(queues[start+1]*cities) + j];
        best_old[1] = cost_matrix[(queues[start+2]*cities) + j];
        best_old[2] = (queues[0] > 1) ? cost_matrix[(queues[start+3]*cities) + j] : HUGE;
        
        std::sort(best_old, best_old+3);
      }

      flip_posi = position_in_queues[flip*cities+j];

      // if the facility is not located on the last position
      queues[flip_posi] = queues[start+length+1];
      position_in_queues[queues[flip_posi]*cities+j] = flip_posi;
      parent = start + ((int) ((flip_posi-start) * 0.5));
      // Start updating
      if ((parent > start) && (cost_matrix[queues[parent]*cities+j] > cost_matrix[queues[flip_posi]*cities+j]))
        upHeap(cost_matrix, cities, j, queues, position_in_queues, start, flip_posi);
      else
        downHeap(cost_matrix, cities, j, queues, position_in_queues, start, flip_posi, length, false);

      if (examcosts) {
        // When closing a facility we must have at least one open left
        best_new[0] = cost_matrix[(queues[start+1]*cities) + j];
        best_new[1] = (queues[0] > 1) ? cost_matrix[(queues[start+2]*cities) + j] : HUGE;
        best_new[2] = (queues[0] > 2) ? cost_matrix[(queues[start+3]*cities) + j] : HUGE;
        
        std::sort(best_new, best_new+3);
        
        if (queues[0] > 1) { 
          if ((best_new[0] > best_old[0]) || (best_new[1] > best_old[1])) {
            affected[maxaffect] = j;
            bestcosts[maxaffect] = best_new[0];
            bestcosts[cities+maxaffect] = best_new[1];
            maxaffect++;
          }
        } // end if
        else {
          affected[maxaffect] = j;
          bestcosts[maxaffect] = best_new[0];
          maxaffect++;
        }
      } // end if examcosts
      
    } // end for j
  } // end if !opened

  else {
    // Facility opened
    for (j = 0; j < cities; j++) {
      // length is already increased - so we put the new element on position j*facilities+length-1
      start = j*facilities;

      if (examcosts) {
        // As the number of opened facilities has already been adjusted...
        // We only close a facility, when at least two were opened...
        best_old[0] = (queues[0] > 1) ? cost_matrix[(queues[start+1]*cities) + j] : HUGE;
        best_old[1] = (queues[0] > 2) ? cost_matrix[(queues[start+2]*cities) + j] : HUGE;
        best_old[2] = (queues[0] > 3) ? cost_matrix[(queues[start+3]*cities) + j] : HUGE;
        
        std::sort(best_old, best_old+3);
      }

      flip_posi = start+length;

      queues[flip_posi] = flip;
      position_in_queues[flip*cities+j] = flip_posi;
      upHeap(cost_matrix, cities, j, queues, position_in_queues, start, flip_posi);
 
      if (examcosts) {
        // There is one that was opened just now
        best_new[0] = cost_matrix[(queues[start+1]*cities) + j];
        best_new[1] = (queues[0] > 1) ? cost_matrix[(queues[start+2]*cities) + j] : HUGE;
        best_new[2] = (queues[0] > 2) ? cost_matrix[(queues[start+3]*cities) + j] : HUGE;
        
        std::sort(best_new, best_new+3);
        
        if (queues[0] >= 2) {
          if (queues[0] == 2) {
            // In this case last time only one facility was opened =>
            // all the second best connections are at maxcost, we need to update all the cities
            affected[maxaffect] = j;
            bestcosts[maxaffect] = best_new[0];
            bestcosts[maxaffect+cities] = best_new[1];
            maxaffect++;
          }
          
          else if ((best_new[0] < best_old[0]) || (best_new[1] < best_old[1])) {
            affected[maxaffect] = j;
            bestcosts[maxaffect] = best_new[0];
            bestcosts[maxaffect+cities] = best_new[1];
            maxaffect++;
          }
        } // end if
      } // end if examcosts
    } // end for j
  } // end if opened - else
} // end update_queue


//###############################################################


// This is just a test procedure for debugging - tests whether the queues and updates are working correctly
bool gain_check(const double *open_cost, const double *cost_matrix, const double maxcost, const int facilities, const int cities,
                const int *change, const bool *opened, const int *queues, const double *gain_open, const double *gain_close,
                const double *cost_close_open, const double *cost_secclose_open)
{
  int close[cities];
  double closest[cities], secclosest[cities];
  int a,b,i;

  for (b = 0; b < cities; b++) {
    closest[b] = secclosest[b] = maxcost;
    close[b] = -1;

    for (a = 0; a < facilities; a++) {
      if (opened[a]) {
        if (cost_matrix[a*cities+b] < closest[b]) {
          secclosest[b] = closest[b];
          closest[b] = cost_matrix[a*cities+b];
          close[b] = a;
        }
        else
          if (cost_matrix[a*cities+b] < secclosest[b])
            secclosest[b] = cost_matrix[a*cities+b];
      }
    } // end for a
    if (change[b] != close[b]) {
      std::cout << "Suboptimal assignment of city " << b << ", " << change[b] << " instead of " << close[b] << std::endl;
      for (i = 1; i <= queues[0]; i++)
        std::cout << i << ": " << queues[b*facilities+i] << ", " << opened[queues[b*facilities+i]] << ", " 
             << cost_matrix[queues[b*facilities+i]*cities+b] << " - ";
      return false;
    }
  } // end for b

  double opengain[facilities], closegain[facilities];
  std::cout.precision(5);
  
  for (a = 0; a < facilities; a++) {
    opengain[a] = -open_cost[a];
    closegain[a] = open_cost[a];

    for (b = 0; b < cities; b++) {
      if (close[b] == a) {
        if (queues[0] > 1)
          closegain[a] -= (secclosest[b] - cost_matrix[a*cities+b]);
        else
          closegain[a] -= (maxcost - cost_matrix[a*cities+b]);
      }
      opengain[a] += MAX(0,(closest[b]-cost_matrix[a*cities+b]));
    }
    if  ((((int) (gain_open[a] * 100)) != ((int) (opengain[a]*100))) || 
            (((int) (gain_close[a] * 100)) != ((int) (closegain[a]*100))))
      std::cout << a << ": " << opened[a] << " - "
           << gain_open[a] << ", " << opengain[a] << " - "
           << gain_close[a] << ", " << closegain[a] << std::endl;
  }

  for (b = 0; b < cities; b++) {
    if ((((int) (cost_close_open[b] * 1000)) != ((int) (closest[b] * 1000))) || 
        (((int) (cost_secclose_open[b] * 1000)) != ((int) (secclosest[b] * 1000))))
      std::cout << b << ": " << change[b] << ", " << close[b] << " - "
           << cost_close_open[b] << ", " << closest[b] << " - "
           << cost_secclose_open[b] << ", " << secclosest[b] << std::endl;
  }
  return true;
}


//###############################################################


// Update the gains of opening and closing a facility and the closest and the second closest facilities
void gain_update(const double *cost_matrix, const double maxcost, const int facilities, const int cities,
                 const int flip, const bool opened, double* gain_close, double *gain_open, double *cost_close_open,
                 double *cost_secclose_open, int *change, int *queues, int *position_in_queues, const int *order)
{
  int r, b, a, facil, maxaffect = 0;
  double t;

  // We just consider cities, that are affected by the change in the solution
  int *affected = new int [cities];
  double *bestcosts = new double [2*cities];

  // if (!opened) cout << " closed.\n"; else cout << " opened.\n";
  if (opened) queues[0]++; else queues[0]--;

  t = time();
  // Update queues - delete or insert facility flip in the queues
  update_queue(cost_matrix, facilities, cities, flip, opened, queues, position_in_queues,
               true, affected, bestcosts, maxaffect);

  int newbest;
  double newbest_conn, new2ndbest_conn = maxcost;
  t = time();
 
  // Update for all cities whose data are subject to change
  for(r = 0; r < maxaffect; r++) {
    b = affected[r];

    // Find the first 3 values - which include the two best connections
    newbest = ((cost_matrix[(queues[b*facilities+1]*cities)+b] > bestcosts[r]) && (queues[0] == 2)) 
      ? queues[b*facilities+2] : queues[b*facilities+1];

    newbest_conn = bestcosts[r];
    new2ndbest_conn = (queues[0] > 1) ? bestcosts[r+cities] : maxcost;

    if (change[b] != newbest) {
      a = 0; facil = order[b*facilities];

      // Newbest is now modified to represent the index of the best connection
      if (newbest_conn > cost_close_open[b]) {
        // Gain updates - see paper for details

        // Facility closed
        // First we check for values smaller than old best connection
        while (cost_matrix[facil*cities + b] < cost_close_open[b]) {
          gain_open[facil] += (newbest_conn - cost_close_open[b]);
          a++;
          facil = order[(b*facilities) + a];
        }
        // Then we check for values between old and new best connection
        while (cost_matrix[facil*cities + b] < newbest_conn) {
          gain_open[facil] += (newbest_conn - cost_matrix[(facil*cities) + b]);
          a++;
          facil = order[(b*facilities) + a];
        }
      } // end if facility closed

      else {
        // Facility opened
        // First we check for values smaller than new best connection
        while (cost_matrix[facil*cities + b] < newbest_conn) {
          gain_open[facil] -= (cost_close_open[b] - newbest_conn);
          a++;
          facil = order[(b*facilities)+a];
        }
        while (cost_matrix[facil*cities + b] < cost_close_open[b]) {
          gain_open[facil] -= (cost_close_open[b] - cost_matrix[(facil*cities) + b]);
          a++;
          facil = order[(b*facilities)+a];
        }
      } // end if facilities
    } // end if change[b] != newbest
      
      
    gain_close[change[b]] += (cost_secclose_open[b] - cost_close_open[b]);
    
    cost_close_open[b] = newbest_conn;
    cost_secclose_open[b] = new2ndbest_conn;
    change[b] = newbest;
    
    // After change update with new values
    gain_close[change[b]] += (cost_close_open[b] - cost_secclose_open[b]);
      
    
  } // end for

  delete[] affected;
  delete[] bestcosts;
}


//###############################################################


// Initializing 
void local_begin(const double *open_cost, const double *cost_matrix, const int facilities, const int cities,
                 const double maxcost, bool *opened, int *queues, int *position_in_queues, double &cost,
                 int *change, int *connected, double *gain_open, double *gain_close,
                 double *cost_close_open, double *cost_secclose_open)
{
  int a,b,i,facil, maxaffect;
  cost = 0;
  i = queues[0] = 0;
  
  if (!BEST_START) {
    // If BEST_START is 1, we start with an optimal solution
    // regarding connection costs. If not, we construct a random
    // initial solution:

     // Open each facility at random
    for (facil = 0; facil < facilities; facil++)
      if (rand() < (RAND_MAX *.5)) {
        cost += open_cost[facil];
        opened[facil] = true;
        queues[0]++;
        maxaffect = 0;
        update_queue(cost_matrix, facilities, cities, facil, true, queues, position_in_queues, false, NULL, NULL, maxaffect);
      }

    // But open at least one facility
    facil =  (int) (((double) rand() / RAND_MAX) * facilities);
    if (facil == facilities) facil--;

    if (!opened[facil]) {
      queues[0]++;
      cost += open_cost[facil];
      opened[facil] = true;
      maxaffect = 0;        
      update_queue(cost_matrix, facilities, cities, facil, true, queues, position_in_queues, false, NULL, NULL, maxaffect);
    }
  }
  else {
    // open all facilities
    for (facil = 0; facil < facilities; facil++) {
      opened[facil] = true;
      cost += open_cost[facil];
      queues[0]++;
      maxaffect = 0;
      update_queue(cost_matrix, facilities, cities, facil, true, queues, position_in_queues, false, NULL, NULL, maxaffect);
    }
  }


  // Fill up arrays
  for (b = 0; b < cities; b++) {
    facil = connected[b] = change[b] = queues[b*facilities+1];
          cost += cost_close_open[b] = cost_matrix[(facil*cities) + b];

    if (queues[0] < 2)
      cost_secclose_open[b] = maxcost;
    else if (queues[0] < 3)
      cost_secclose_open[b] = cost_matrix[queues[b*facilities+2]*cities+b];
    else
      cost_secclose_open[b] = MIN(cost_matrix[queues[b*facilities+2]*cities+b],cost_matrix[queues[b*facilities+3]*cities+b]);

    // Update gains
    gain_close[change[b]] += (cost_close_open[b] - cost_secclose_open[b]);
    for (a = 0; a < facilities; a++)
      gain_open[a] += MAX(0,cost_close_open[b]-cost_matrix[(a*cities)+b]);
  }
} // end local_begin


//###############################################################


// Find the best flip and return the number of it
int find_best_flip(bool *opened, double *gain_open, double *gain_close, int start, int facilities,
                   bool adjust, bool switchvalue, double &gain_best)
{
  int flip, a, found;

  gain_best = -1;
  flip = found = 0;

  for (a = start; a < facilities; a++)
    if ((!adjust) || (opened[a] == switchvalue))
      if (opened[a]) {
        if (gain_close[a] > gain_best) {
          gain_best = gain_close[a];
          flip = a;
          found = 1;
        }
        else if (gain_close[a] == gain_best) {
          found++;
        if (found * rand() < RAND_MAX)
          flip = a;
        }
      }
      else {
        if (gain_open[a] > gain_best) {
          gain_best = gain_open[a];
          flip = a;
          found = 1;
        }
        else if (gain_open[a] == gain_best) {
          found++;
          if (found * rand() < RAND_MAX)
            flip = a;
        }
      }

  return flip;
} // end find_best_flip


//##############################################################


// Main algorithm - local search for uncapacitated facility location
bool UNCAP_FACILITY_LOCATION_LOCAL_RUN(const double *open_cost, const double *cost_matrix, const int facilities,
                                   const int cities, const double delta, int *connected, double& cost)
{
  const double epsilon = 0.1; // for the acceptance criterion
  const double polynom = facilities + cities; // for the acceptance criterion
  const int edges = facilities * cities;
  const double ratio = (double) epsilon / polynom;

  double adjcost_save, adjcost, realcost, maxcost = 0;

  int a2, a, b, i, maxaffect,
      facil,
      flip;           // Facility chosen to flip opened/unopened status

  int *change = new int [cities]; // New best solution candidate
  int *change_save = new int [cities]; // Save-array for exchange steps

  double gain_best;

  // For every city the cost of the connection to the cheapest and
  // the second cheapest facility
  double *cost_close_open = new double [cities];
  double *cost_secclose_open = new double [cities];

  // adjusted opening cost
  double *adjopen_cost = new double [facilities];

  // Gains of opening and closing facilities
  double *gain_open = new double [facilities];
  double *gain_close = new double [facilities]; 

  double *cost_close_open_save = new double [cities];
  double *cost_secclose_open_save = new double [cities];

  // Arrays are saved when exchange move is applied
  double *gain_open_save = new double [facilities];
  double *gain_close_save = new double [facilities];

  // Priority queues to queue up the opened facilities
  int *queues = new int [edges+1];
  int *position_in_queues = new int [edges];

  bool *opened = new bool [facilities]; // Indicates open status in the current candidate
  bool val;                             // return - value
  bool exit_loop, exit_fliploop;        // Variables to indicate whether we look for a simple flip
                                        // and whether there is any improvement left at all

  int *order = new int [edges]; // on b*facilities + x we have the facilities in descending order
                                // of connection costs to facility b
  
  // For ordering the connections to a city
  double *helpcost = new double [facilities];
  int *helpindex = new int [facilities];
  int *temp = new int [facilities];

  for (b = 0; b < cities; b++) {
    for (a = 0; a < facilities; a++) {
      helpcost[a] = cost_matrix[(a*cities) + b];
      helpindex[a] = a;
    }

    mergesort(helpcost, temp, 0, facilities-1, helpindex);
    for(a = 0; a < facilities; a++)
      order[(b*facilities)+a] = helpindex[a];
  }

  delete[] helpindex;
  delete[] helpcost;
  delete[] temp;

  val = exit_loop = exit_fliploop = false;

  // Init arrays and gains
  for (a = 0; a < facilities; a++) {
    opened[a] = false;
    adjopen_cost[a] = delta * open_cost[a];
    gain_open[a] = -adjopen_cost[a];
    gain_close[a] = adjopen_cost[a];
    maxcost += adjopen_cost[a];
    for (b = 0; b < cities; b++)
      maxcost += cost_matrix[a*cities+b];
  }

  // Init queues
  for (i = 0; i < edges; i++) {
    position_in_queues[i] = 0;
    queues[i+1] = 0;
  }

  for (b = 0; b < cities; b++) {
    connected[b] = change[b] = -1;
    cost_close_open[b] = cost_secclose_open[b] = maxcost;
  }

  srand((unsigned int) time());

  // Init solution
  local_begin(adjopen_cost, cost_matrix, facilities, cities, maxcost, opened, queues, position_in_queues, adjcost,
              change, connected, gain_open, gain_close, cost_close_open, cost_secclose_open);

  flip = 0;

  // If the problem is trivial, we exit at this point
  if (facilities == 1) {
    val = true;
    goto TERMINATE;
  }

  /* This is the main loop of the algorithm. The switches are maintained incrementally.
     Switch is here only switching the status of one facility from opend to closed or vice versa. 
     If a facility is switched, we just have to add the corresponding gain to the cost and update 
     the gains. If we need to apply an exchange move we apply a switch and check every possible 
     switch afterwards. If there's not enough improvement we recover the situation. */

  cost = realcost = HUGE;

  while (!exit_loop) {

    while (!exit_fliploop) {

      // If we have scaled the cost, we have to check, whether we have a
      // new optimum on the unscaled problem.
      realcost = adjcost;
      for (a = 0; a < facilities; a++)
        realcost += (1 - delta) * opened[a] * open_cost[a];

      if (realcost < cost) {
        cost = realcost;
        for (b = 0; b < cities; b++) connected[b] = change[b];
      }

      // Look for a flip that improves the solution
      flip = find_best_flip(opened, gain_open, gain_close, 0, facilities, 0, 0, gain_best);

      if (gain_best < adjcost * ratio) {
        // If there is no facility that offers enough improvement,
        // we exit and check switches
        exit_fliploop = true;
      }
      else {
        // Do the switch
        adjcost -= (opened[flip]) ? gain_close[flip] : gain_open[flip];
        opened[flip] = !opened[flip];
        // Update the gains
        gain_update(cost_matrix, maxcost, facilities, cities, flip, opened[flip],
                    gain_close, gain_open, cost_close_open, cost_secclose_open, change, 
                    queues, position_in_queues, order);
      }

    } // end while fliploop

    // Now we check exchange moves - first we save important values
    for (a = 0; a < facilities; a++) {
      gain_close_save[a] = gain_close[a];
      gain_open_save[a] = gain_open[a];
    }

    for (b = 0; b < cities; b++) {
      cost_close_open_save[b] = cost_close_open[b];
      cost_secclose_open_save[b] = cost_secclose_open[b];
      change_save[b] = change[b];
    }

    adjcost_save = adjcost;
    a = 0;
    exit_loop = true;

    // Here's the main loop for exchange moves - we apply every possible switch and check
    // all switches that can be applied afterwards
    while ((a < facilities) && (adjcost_save - adjcost < adjcost_save * ratio)) {
      
      // If there is only one open facility left, we should open a facility first, to stay
      // in the feasible search space
      if ((queues[0] > 1) || (!opened[a])) {
        // Apply switch
        adjcost -= opened[a] ? gain_close[a] : gain_open[a];
        opened[a] = !opened[a];

        gain_update(cost_matrix, maxcost, facilities, cities, a, opened[a],
                    gain_close, gain_open, cost_close_open, cost_secclose_open, change, queues, position_in_queues, order);

        // OK- now check all possible switches that would complete an exchange move
        if ((queues[0] == 2) && (opened[a]))
          flip = find_best_flip(opened, gain_open, gain_close, 0, facilities, 1, opened[a], gain_best);
        else
          flip = find_best_flip(opened, gain_open, gain_close, a+1, facilities, 1, opened[a], gain_best);

        // Does the best possible flip satisfy the condition
        if (adjcost - gain_best < adjcost_save*(1 - ratio)) {
          // If yes, apply the move and ...
          adjcost -= (opened[flip]) ? gain_close[flip] : gain_open[flip];
          opened[flip] = !opened[flip];

          gain_update(cost_matrix, maxcost, facilities, cities, flip, opened[flip],
                      gain_close, gain_open, cost_close_open, cost_secclose_open, 
                      change, queues, position_in_queues, order);

          // ...try simple switches again next time
          exit_loop = exit_fliploop = false;
        }
        else {
          // If not - recover the situation when entered the exchange loop
          opened[a] = !opened[a];
          queues[0] += (opened[a]) ? 1 : -1;
          maxaffect = 0;
          update_queue(cost_matrix, facilities, cities, a, opened[a], queues, position_in_queues, false, NULL, NULL, maxaffect);

          // Recover arrays
          for (a2 = 0; a2 < facilities; a2++) {
            gain_close[a2] = gain_close_save[a2];
            gain_open[a2] = gain_open_save[a2];
          }

          for (b = 0; b < cities; b++) {
            cost_close_open[b] = cost_close_open_save[b];
            cost_secclose_open[b] = cost_secclose_open_save[b];
            change[b] = change_save[b];        

            // We need the chosen facility on first queue-position 
            // (maybe there are others with same cost)
            if ((change[b] == queues[b*facilities+2]) || (change[b] == queues[b*facilities+3])) {
              queues[position_in_queues[change[b]*cities+b]] = queues[b*facilities+1];
              position_in_queues[queues[b*facilities+1]*cities+b] = position_in_queues[change[b]*cities+b];
              position_in_queues[change[b]*cities+b] = b*facilities+1;
              queues[b*facilities+1] = change[b];
            }

          }

          adjcost = adjcost_save;
                    
        }
      } // if - feasible region ensurance
      a++;
    } // end while testing exchange moves

  } // end while testing all neighborhood moves


  val = true;

 TERMINATE:

  if (val) {
    // Recalculate costs
    cost = 0;
    for (a = 0; a < facilities; a++)
      opened[a] = false;

    for (b = 0; b < cities; b++) {
      facil = connected[b];
      cost += cost_matrix[(facil*cities)+b];
      if (!opened[facil]) {
        cost += open_cost[facil];
        opened[facil] = true;
      }
    }
  } // end if val


  delete[] opened;
 
  delete[] gain_close;
  delete[] gain_open;
  delete[] cost_close_open;
  delete[] cost_secclose_open;

  delete[] gain_close_save;
  delete[] gain_open_save;
  delete[] cost_close_open_save;
  delete[] cost_secclose_open_save;
  delete[] order;

  delete[] change;
  delete[] queues;

  return val;
}


//###############################################################


// Call of algorithm without scaling
bool UNCAP_FACILITY_LOCATION_LOCAL(const double *open_cost, const double *cost_matrix, const int facilities,
                                   const int cities, int *connected, double& cost)
{
  return(UNCAP_FACILITY_LOCATION_LOCAL_RUN(open_cost, cost_matrix, facilities, cities, 1.0, connected, cost));
}


//###############################################################


// Call of algorithm with scaling
bool UNCAP_FACILITY_LOCATION_SCALED_LOCAL(const double *open_cost, const double *cost_matrix, const int facilities,
                                          const int cities, int *connected, double& cost)
{
  return(UNCAP_FACILITY_LOCATION_LOCAL_RUN(open_cost, cost_matrix, facilities, cities, sqrt(2), connected, cost));
}


//###############################################################


// Tabu Search for uncapacitated facility location
bool UNCAP_FACILITY_LOCATION_TABU_RUN(const double *open_cost, const double *cost_matrix,
                                      const int facilities, const int cities, const int maxruns, 
                                      int *connected, double& best_cost)
{ 
  const int edges = facilities * cities;

  int maxlength = (int) MIN(10,facilities - 1);           // Maximum length of tabu list
  double maxcost = 0;

  int a, b, it,
      failedruns,
      tabu_length = maxlength;
  int found,          // Number of best switches found
      flip;           // Facility chosen to flip opened/unopened status


  int *tabu = new int [facilities];         // Tabu status for all facilities
  int *change = new int [cities];           // New best solution candidate

  // Queues for finding best and second best connetions to opened facilities
  int *queues = new int [edges + 1];
  int *position_in_queues = new int [edges];

  int *order = new int [edges]; // on b*facilities + x we have the facilities in descending order
                                // of connection costs to facility b


  // For building up order
  double *helpcost = new double [facilities];
  int *helpindex = new int [facilities];
  int *temp = new int [facilities];

  for (b = 0; b < cities; b++) {
    for (a = 0; a < facilities; a++) {
      helpcost[a] = cost_matrix[(a*cities) + b];
      helpindex[a] = a;
    }

    mergesort(helpcost, temp, 0, facilities-1, helpindex);
    for(a = 0; a < facilities; a++)
      order[(b*facilities)+a] = helpindex[a];
  }

  delete[] helpindex;
  delete[] helpcost;
  delete[] temp;

  double cost, gain_best;

  // For every city the cost of the connection to the cheapest and
  // the second cheapest facility
  double *cost_close_open = new double [cities];
  double *cost_secclose_open = new double [cities];

  // Gains of opening and closing a facility
  double *gain_open = new double [facilities];
  double *gain_close = new double [facilities];

  bool *opened = new bool [facilities];        // Indicates open status in the current candidate
  bool *open_best = new bool [facilities];     // Indicates open status in the current best solution
  bool val = false;

  // Init arrays and gains
  for (a = 0; a < facilities; a++) {
    opened[a] = open_best[a] = false;
    gain_open[a] = -open_cost[a];
    gain_close[a] = open_cost[a];
    tabu[a] = 0;
    maxcost += open_cost[a];
    for (b = 0; b < cities; b++)
      maxcost += cost_matrix[a*cities+b];
  }

  for (b = 0; b < cities; b++) {
    change[b] = -1;
    cost_close_open[b] = cost_secclose_open[b] = maxcost;
  }

  srand((unsigned int) time());

  // Initialize solution
  local_begin(open_cost, cost_matrix, facilities, cities, maxcost, opened, queues, position_in_queues, cost,
              change, connected, gain_open, gain_close, cost_close_open, cost_secclose_open);

  for (a = 0; a < facilities; a++)
    open_best[a] = opened[a];

  best_cost = cost;

  it = failedruns = flip = found = 0;

  // If the problem is trivial, we exit at this point
  if (facilities == 1) {
    val = true;
    goto TERMINATE;
  }


  /* This is the main loop of the algorithm. The switches are maintained incrementally.
     In opposite to the local algorithm here we only regard switching the status of one
     facility from opend to closed or vice versa. If a facility is switched, we just
     have to add the corresponding gain to the cost and update the gains */

  while (failedruns < maxruns) {
    // cout << cost << ", " << failedruns << ", " << best_cost << " -!- ";

    // Look for a switch that improves the solution
    gain_best = -1;
    for (a = 0; a < facilities; a++)
      if (tabu[a] <= it)
        if (opened[a]) {
          if (gain_close[a] > gain_best) {
            gain_best = gain_close[a];
            flip = a;
            found = 1;
          }
          else if (gain_close[a] == gain_best) {
            found++;
            if (found * rand() < RAND_MAX)
              flip = a;
          }
        }
        else {
          if (gain_open[a] > gain_best) {
            gain_best = gain_open[a];
            flip = a;
            found = 1;
          }
          else if (gain_open[a] == gain_best) {
            found++;
            if (found * rand() < RAND_MAX)
              flip = a;
          }
        }

    // cout << "Best: " << gain_best << endl;

    if (gain_best >= 0) {
      // Flip one of the facilities that have best gain
      // cout << "Facility " << flip;
      // and update tabu lists using standard scheme

      tabu[flip] = it + tabu_length;
      if ((gain_best > 0) && (tabu_length > 2))
        tabu_length--;
      if ((gain_best <= 0) && (tabu_length < maxlength))
        tabu_length++;
      it++;
    }

    else {
      // If there is no facility that offers improvement,
      // we randomly close an opened facility
      if (queues[0] > 1) {
        a = (int) (queues[0]*((double) rand() / RAND_MAX));
        if (a == queues[0]) a--;

        flip = -1;
        do {
          flip++;
          a -= opened[flip];
        } while ((a >=0) && (flip < facilities));

      }
      // if there is just one open facility left, we have to open one randomly
      else {
        /* Now we have a dilemma: No opening improves the solution, but
           we cannot close a facility any more because there's only one left open.
        
           Alternative 1: Just cancel search and exit with best found solution */

        //        val = true;
        // goto TERMINATE;

        // Alternative 2: Open a random facility and continue
        
        do {
          flip = (int) (facilities * ((double) rand() / RAND_MAX));
          if (flip == facilities) flip--;

        } while (opened[flip]);
        
      }

      // cout << "Random !! - Gain: ";
      // if (opened[flip]) cout << gain_close[flip]; else cout << gain_open[flip];
      // cout << ", - " << queues[0] << " - Facility " << flip;
    }

    // Do the switch
    cost -= (opened[flip]) ? gain_close[flip] : gain_open[flip];
    opened[flip] = !opened[flip];

    // Update gains
    gain_update(cost_matrix, maxcost, facilities, cities, flip, opened[flip],
                gain_close, gain_open, cost_close_open, cost_secclose_open, change, 
                queues, position_in_queues, order);

    // Do we have a new best solution ?
    if (cost < best_cost) {  
      cost = 0;
      for (a = 0; a < facilities; a++)
        cost += opened[a] * open_cost[a];
      for (b = 0; b < cities; b++)
        cost += cost_matrix[(change[b]*cities) + b];
      if (cost < best_cost) {

        // cout.setf(ios::fixed);
        // cout.precision(7);
        // cout << cost << endl;

        best_cost = cost;     

        // If the solution differs from the old one - update
        for (b = 0; b < cities; b++) connected[b] = change[b];
        failedruns = 0;
      }

      // otherwise keep increasing failedruns
      else failedruns++;
    }
    else failedruns++;

    //    if ((failedruns % 100) == 1) cout << "f: " << failedruns << endl;
  } // end while failedruns < maxruns

  val = true;

 TERMINATE:

  delete[] tabu;
  delete[] change;

  delete[] queues;
  delete[] position_in_queues;

  delete[] cost_close_open;
  delete[] cost_secclose_open;

  delete[] gain_open;
  delete[] gain_close;
  delete[] order;

  delete[] opened;
  delete[] open_best;

  return val;
}


//###############################################################


// Tabu search with 500 maxrun
bool UNCAP_FACILITY_LOCATION_TABU(const double *open_cost, const double *cost_matrix,
                                  const int facilities, const int cities, int *connected, double& best_cost)
{
  return(UNCAP_FACILITY_LOCATION_TABU_RUN(open_cost, cost_matrix, facilities, cities, 500, connected, best_cost));
}


//###############################################################


// Tabu search with 250 maxrun
bool UNCAP_FACILITY_LOCATION_TABU250(const double *open_cost, const double *cost_matrix,
                                      const int facilities, const int cities, int *connected, double& best_cost)
{
  return(UNCAP_FACILITY_LOCATION_TABU_RUN(open_cost, cost_matrix, facilities, cities, 250, connected, best_cost));
}
