#include <cstdlib>
#include <iostream>
#include <fstream>
#include <cmath>
#include <sys/time.h>

// A little procedure to read floating point numbers from an input string
double numberize(std::ifstream& input, int &precise)
{
  char c;
  double number = 0;
  bool negative, after;

  precise = 0;
  negative = after = false;
  
  // Pass SPACE-characters
  while (((c = input.get()) == ' ') || (c == '\n'));

  // Read double-type number from input-stream
  if (c == '-') negative = true;
  while((c != ' ') && 
	(c != '\n') && 
	(!input.eof())) {
    if (c == '.') after = true;
    else if ((c < 48) || (c > 57)) number = -1; //return;
    else {
      //  cout << c;
      number = (number * 10) + (c - 48);
      if (after) precise++;
    }
    c = input.get();
  }

  number = number * pow(10,(-precise));
  if (negative) number = -number;
  // cout << "\nNumber is: " << number << endl;
  return number;
}


// Get the time
double time()
{
  struct timeval tp;
  gettimeofday(&tp, NULL);
  return double(tp.tv_sec)  + tp.tv_usec/1000000. ;
}


// Sorting the order-array, which contains the indices to cost_matrix, using temp
void mergesort(const double *cost_matrix, int *temp, const int left, const int right, int *order)
{
  int mitte = (int) (0.5*(left + right));
  int i, lpos = left;
  int rpos = mitte + 1;
 
  if (left < right-1) {    
    mergesort(cost_matrix, temp, left, mitte, order);
    mergesort(cost_matrix, temp, mitte + 1,right, order);

    for (i = 0; i < right-left+1; i++) 
      if ((rpos > right) || ((cost_matrix[order[lpos]] < cost_matrix[order[rpos]]) && (lpos < mitte+1))) {
	temp[i] = order[lpos];
        lpos++;
      }
      else{
	temp[i] = order[rpos];
	rpos++;
      }

    for (i = 0; i < right-left+1; i++)
      order[left+i] = temp[i];
    
  }
  else 
    if (cost_matrix[order[left]] > cost_matrix[order[right]]){
      temp[0] = order[left];
      order[left] = order[right];
      order[right] = temp[0];
    }
} // end mergesort



// Testing whether a problem is metric - 
// and if not then output the path that is cheaper than the direct connection
// Floyds algorithm
int path(const int a, const int b, const int cnt, const int locations, const int *inter, int *way)
{
  int k;
  k = inter[(a*locations)+b];
  if (k == -1) return cnt;
  int number = path(a, k, cnt, locations, inter, way);
  way[number] = k;
  number = path(k, b, number+1, locations, inter, way);
  return number;
}


bool test_metric(const double *cost_matrix, const int facilities, const int cities, int& facil, int& city, int& length, int* way)
{
  const int locations = facilities+cities;

  double *shorty = new double [locations*locations];
  int *inter;
  bool buildway = false;

  if (locations <= 600) 
    buildway = true;
    inter = new int [locations*locations];

  int a,k,b = 0;
  bool keepon;


  for (a = 0; a < locations; a++)
    for (b = 0; b < locations; b++) {
      shorty[(a*locations)+b] = HUGE;
      if (buildway) inter[(a*locations)+b] = -1;    
    }

  for (a = 0; a < facilities; a++)
    for (b = facilities; b < locations; b++)
      shorty[(a*locations)+b] = shorty[(b*locations)+a] = cost_matrix[(a*cities)+(b-facilities)];

  keepon = true;
  a = 0;
  while ((a < locations) && (keepon)) {
    b = 0;
    while ((b < locations) && (keepon)) {
      k = 0;
      while ((k < locations) && (keepon)) {
	if (shorty[(a*locations)+b] > shorty[(a*locations)+k] + shorty[(k*locations)+b]) {
	  shorty[(a*locations)+b] = shorty[(a*locations)+k] + shorty[(k*locations)+b];
	  if (buildway) inter[(a*locations)+b] = k;
	  if ((a < facilities) && (b >= facilities) &&
	      (shorty[(a*locations)+b] < cost_matrix[(a*cities)+(b-facilities)])) keepon = false;
	}
	if (keepon) k++;
      }
      if (keepon) b++;
    }
    if (keepon) a++;
  }
  
  if (!keepon) {
    std::cout << "Shortest: " << shorty[(a*locations)+b] << ", direct: " << cost_matrix[(a*cities)+(b-facilities)] << std::endl;
    length = (buildway) ? path(a, b, 0, locations, inter, way) : 0;
    facil = a;
    city = b - facilities;
    return 0;
  }

  return 1;
}
