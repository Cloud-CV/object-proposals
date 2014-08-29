#ifndef HELPER_H
#define HELPER_H

#include <fstream>
#include <vector>
#include <assert.h>
#include <iostream>
#include <stdlib.h>

typedef unsigned int uint;
typedef unsigned char uchar;

bool Between0And1(const double a){
  return ((a>=0.0) && (a<=1.0));
}

std::vector<double> ReadAlphaFromFile( const std::string& filename){
  
  std::vector<double> alpha(65536);
  assert(alpha.size()==65536);

  std::ifstream myfile (filename.c_str());
  if (myfile.is_open())
  {
    double val;
    uint k=0;
    while ( myfile>>val )
    {
      assert(alpha.size()>k);
      alpha.at(k)=val;

#ifndef NDEBUG
      if(k>0)
        assert(alpha.at(k)>=alpha.at(k-1));
#endif

      k++;
      if(k>65536){
        std::cout<<"Error: There should be exactly 65536 lines in the alpha file.\n";
        exit(-1);
      }
    }
    myfile.close();
  }else{
    std::cout << "Unable to read file. This program will now abort."; 
    exit(-1);
  }

  return alpha;
}

#endif
