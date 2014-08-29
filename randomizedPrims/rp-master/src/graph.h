#ifndef GRAPH
#define GRAPH

#include <map>
#include <vector>
#include <assert.h>
#include <algorithm>
#include <iostream>
#include <math.h>
#include "params.h"
#include "image.h"
#include "seg_image.h"
#include "nhist3.h"

typedef unsigned int uint;

class Graph{

  public:

    Graph(const Image& im, const SegImage& segIm, const Params::FWeights& fWeights);

    Graph(const double* S, const uint rowsS, const uint nNodes); //For reading simmatrix from matlab

    inline std::vector<std::pair<uint, double> > getNOfNode(const uint k) const{return x_.at(k).N_;};

    inline double getS(const uint i, const uint j) const{return S_.at(i).at(j);};

  private:

    class Node{
      public:
        std::vector<std::pair<uint, double> > N_;//Neighbors
    };

    std::vector<Node> x_; //Nodes with their neighborhoods
    std::vector<std::vector<double> > S_; //Similarity matrix (full matrix)

    void BuildGraphFromS();
};

Graph::Graph(const double* S, const uint rowsS, const uint nNodes):S_(nNodes, std::vector<double>(nNodes,0.0)){
  uint i=0, j=0;
  double e=0.0;
  for(uint k=0; k<rowsS;k++){
    i=(uint)S[k];
    j=(uint)S[k+rowsS];

    e=S_.at(i).at(j);
    assert(fabs(S_.at(i).at(j)-0.0)<5E-5);
    assert(fabs(S_.at(j).at(i)-0.0)<5E-5);
    S_.at(i).at(j)=e;
    S_.at(j).at(i)=e;
  }


  this->BuildGraphFromS();

}

void Graph::BuildGraphFromS(){
  uint nNodes=S_.size();

  x_=std::vector<Node>(nNodes,Node());

  uint i=0, j=0;
  double e=0.0;
  for(uint i=0; i<nNodes;i++){
    for(uint j=0; j<i; j++){
      assert(S_.at(i).at(j)==S_.at(j).at(i));
      e=S_.at(i).at(j);
      if(e>5E-5){
        x_.at(i).N_.push_back(std::pair<uint, double>(j,e));
        x_.at(j).N_.push_back(std::pair<uint, double>(i,e));
      }
    }
  }
}

Graph::Graph(const Image& rgbI, const SegImage& segIm, const Params::FWeights& fWeights){

  //TODO:Precompute features and similarities and save similarity graph.

  const std::vector< std::vector<uint> >& coMatrix=segIm.coMatrix();
  const uint nSps=segIm.nSps();

  //Preprocess LAB color histograms

  Image labI(rgbI.convertToColorspace(LAB));

  std::vector<NHist3> labCHists;
  labCHists.reserve(nSps);
  for(uint i=0; i<nSps;i++){
    NHist3 nh(labI, segIm.pixelList(i), 16);
    labCHists.push_back(nh);
  }

  //Compute pairwise similarities

  double s=0.0, sCBorder=0.0, sCHist=0.0, sSize=0.0;
  const double& wCBorder=fWeights.wCommonBorder_, 
        wCHist=fWeights.wLABColorHist_, wSize=fWeights.wSizePer_;
  const double wsBias=fWeights.wBias_; //Complete bias! (similarity*weight)
  S_ = std::vector<std::vector<double> >(nSps, std::vector<double>(nSps,0.0));

  uint la=0, lb=0, lc=0;
  for(uint i=0; i<nSps;i++){
    la=segIm.perimeter(i);
    for(uint j=0; j<i;j++){
      assert(i>j); //Lower triangle
      if(coMatrix.at(i).at(j)>0){
        //The superpixels are connected, so we compute their similarity features

        //Size
        if(wSize){
          assert(Between0And1(segIm.normArea(i)));
          assert(Between0And1(segIm.normArea(j)));
          sSize=(1.0-segIm.normArea(i)-segIm.normArea(j));
        }else{
          sSize=0.0;
        }
        assert(sSize>=0.0);
        assert(sSize<=1.0);

        //Common border
        if(wCBorder){
          lb=segIm.perimeter(j);
          lc=coMatrix.at(i).at(j);
          assert(coMatrix.at(i).at(j)==coMatrix.at(j).at(i));
          sCBorder=std::max((double)lc/(double)la,(double)lc/(double)lb);
        }else{
          sCBorder=0.0;
        }
        assert(sCBorder>=0.0);
        assert(sCBorder<=1.0);

        //LAB Color Hist
        if(wCHist){
          sCHist=labCHists.at(i).Intersect(labCHists.at(j));
        }else{
          sCHist=0.0;
        }
        assert(sCHist>=0.0);
        assert(sCHist<=1.0);

        //Integration:
        s=1.0/(1.0+exp(wsBias+wSize*sSize+wCBorder*sCBorder+wCHist*sCHist));

        assert(s>=0.0 && s<=1.0);

        S_.at(i).at(j)=s;
        S_.at(j).at(i)=s;
      }
    }
  }

  this->BuildGraphFromS();
}

#endif



















