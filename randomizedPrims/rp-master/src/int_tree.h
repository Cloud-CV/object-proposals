#ifndef INT_TREE_H
#define INT_TREE_H

#include <map>
#include <vector>
#include <assert.h>
#include <algorithm>
#include <iostream>
#include <math.h>

typedef unsigned int uint;
 
class IntTree{

  public:
  class Node{

    protected:

      double e_;//Edge weight
      uint i_;//Initial sp id
      uint j_;//Neighbour sp id
      double W_;//Sum of childrens W (integral weight)
      std::vector<double>::iterator ptr_; 
    public:

      Node(const double e, const uint i, const uint j, const std::vector<double>::iterator ptr):e_(e), i_(i), j_(j), W_(-1), ptr_(ptr){};
      
      Node(const double e, const uint i, const uint j, const double W, const std::vector<double>::iterator ptr):e_(e), i_(i), j_(j), W_(W), ptr_(ptr){};

      Node( const Node& rhs ):e_(rhs.e()),i_(rhs.i()),j_(rhs.j()),W_(rhs.W()),ptr_(rhs.ptr()){};

      inline double e() const{ return e_;}
      inline uint i() const{ return i_;}
      inline uint j() const{ return j_;}
      inline double W() const{ return W_;}
      inline std::vector<double>::iterator ptr() const{ return ptr_;}


      void setW(const double W){W_=W;};
  };

  IntTree(const uint N);
  IntTree(const std::vector<Node> x, const uint N);
  void AddNode(const Node& n);
  void RemoveNode(const uint i,const uint j);
  void Reset();

  inline Node getNode(const uint i, const uint j)const;

  inline Node SampleNode(const double r);

  inline std::vector<Node> x(){return x_;};

  bool AreWConsistent();

  private:
  std::vector<Node> x_;
  std::vector<std::vector<int> > mapIJ_; //Indexing for fast removal
  uint nActiveNodes_;
  std::vector<std::pair<uint, uint> > nzsMapIJ_; //For fast clearing of mapIJ_

  IntTree();


};

IntTree::IntTree(const std::vector<Node> x, const uint N){

  assert(N>0);
  assert(x.size()>0);

  x_.push_back(x.at(0));
  x_.at(0).setW(x_.at(0).e());
  nActiveNodes_=1;


  mapIJ_.resize(N);
  for (uint i = 0; i < N; ++i)
    mapIJ_.at(i).resize(N,-1);

  mapIJ_.at(x_.at(0).i()).at(x_.at(0).j())=0;
  mapIJ_.at(x_.at(0).j()).at(x_.at(0).i())=0;

  nzsMapIJ_.push_back(std::pair<uint, uint>(x_.at(0).i(),x_.at(0).j()));
  nzsMapIJ_.push_back(std::pair<uint, uint>(x_.at(0).j(),x_.at(0).i()));

  for(uint k=1; k<x.size();k++){
    this->AddNode(x.at(k));
  }

}

IntTree::IntTree(const uint N){

  assert(N>0);

  nActiveNodes_=0;

  mapIJ_.resize(N);
  for (uint i = 0; i < N; ++i)
    mapIJ_.at(i).resize(N,-1);

  assert(x_.size()==0);

}

void IntTree::AddNode(const Node& n)
{
  x_.push_back(n);
  const uint N=x_.size();

  x_.at(N-1).setW(x_.at(N-1).e());

  if(N>1){
    int k=(N-2)/2;
    while(k>=0){
      x_.at(k).setW(x_.at(k).W()+n.e());
      if(k==0)
        break; 
      k=(k-1)/2;
    }
  }else{
    //First node of the tree
    x_.at(0).setW(x_.at(0).e());
  }

  assert(n.i()>n.j());//To speed things up

  assert(mapIJ_.at(n.i()).at(n.j())  == -1);
  assert(mapIJ_.at(n.j()).at(n.i())  == -1);
  mapIJ_.at(n.i()).at(n.j())=x_.size()-1;
  mapIJ_.at(n.j()).at(n.i())=x_.size()-1;
  assert((x_.at(mapIJ_.at(n.i()).at(n.j())).i()==n.i()) && (x_.at(mapIJ_.at(n.i()).at(n.j())).j()==n.j()));

  nzsMapIJ_.push_back(std::pair<uint, uint>(n.i(),n.j()));
  nzsMapIJ_.push_back(std::pair<uint, uint>(n.j(),n.i()));

  nActiveNodes_++;
}

void IntTree::RemoveNode(const uint i, const uint j){

  int k=mapIJ_.at(i).at(j); 

  mapIJ_.at(i).at(j)=-1;
  mapIJ_.at(j).at(i)=-1;

  assert(mapIJ_.at(i).at(j)==-1);

  const double e=x_.at(k).e();

  assert((x_.at(k).i()==i) && (x_.at(k).j()==j));
  assert((x_.at(k).W()-e)>-5E-5);

  double newW=std::max(x_.at(k).W()-e,0.0);
  if(newW < 5E-10){
    newW = 0;
  }

  x_.at(k)=Node(0,-1,-1,newW,std::vector<double>::iterator(NULL));

  nActiveNodes_-=1;

  if(k==0)
    return; 

  assert(k>=0);
  k=(k-1)/2;
  while(k>=0){

    assert((x_.at(k).W()-e)>-5E-5);

    newW=std::max(x_.at(k).W()-e,0.0);

    assert(newW>=0);
    if(newW < 5E-10){
      newW = 0;
    }
    x_.at(k).setW(newW);
    if(k==0){
      return;
    }else{ 
      k=(k-1)/2;
    }
  }
}

inline IntTree::Node IntTree::SampleNode(const double r){

  assert(r>=0 && r<=1);
  assert(x_.at(0).W()>0);
  double rw=r*x_.at(0).W();
  assert(rw>=0);

  uint k=0, jl=0, jr=0;
  double Wl=0.0, e=0.0, wc1=0.0, wc2=0.0;
  while(1){

    assert(x_.at(k).W()>5E-10); //Otherwise it should not have gotten here.

    e=x_.at(k).e();

    assert(nActiveNodes_>0);
    assert(rw>=0.0);
    assert(rw<=x_.at(k).W());

    wc1=rw-e;
    if(wc1<0){
      assert(e>0);
      return x_.at(k);
    }

    //There should be a left child
    jl=2*k+1;

    Wl=x_.at(jl).W();

    wc2=wc1-Wl;
    if(wc2<0){
      assert(x_.at(jl).W() > 5E-10);
      rw=wc1;
      k=jl;
    }else{
      //There should be a right child
      jr=jl+1;
      assert(x_.at(jr).W() > 5E-10);
      rw=wc2;
      k=jr;
    }
  }

}

bool IntTree::AreWConsistent(){
  for(uint k=0; k<x_.size();k++){

    double W2test=x_.at(k).W();
    double Wgood=x_.at(k).e();

    uint jl=2*k+1;
    uint jr=jl+1;

    if(jl<x_.size())
      Wgood+=x_.at(jl).W();

    if(jr<x_.size())
      Wgood+=x_.at(jr).W();

    if(fabs(Wgood-W2test)>5E-5){
      return false;
    }
    if((W2test-x_.at(k).e())<-5E-5){
      return false;
    }
  }
  return true;
}

void IntTree::Reset(){

  x_.clear();
  nActiveNodes_=0;

  uint i = 0, j = 0;
  for( uint k = 0; k < nzsMapIJ_.size(); k++){
    i=nzsMapIJ_.at(k).first;
    j=nzsMapIJ_.at(k).second;
    mapIJ_.at(i).at(j)=-1;
  }

  nzsMapIJ_.clear();

}

#endif



















