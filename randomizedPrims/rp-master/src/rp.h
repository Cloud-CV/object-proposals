#ifndef RP_H
#define RP_H

#include "int_tree.h"
#include "graph.h"
#include "image.h"
#include "seg_image.h"
#include "params.h"
#include "stopwatch/Stopwatch.h"

#if !defined(MAX)
#define    MAX(A, B)    ((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define    MIN(A, B)    ((A) < (B) ? (A) : (B))
#endif

double Unif01(){
  return ((double) rand() / (double) (RAND_MAX+1.0));
}

std::vector<BBox> RP(const Image& rgbI, const Params& params){

  /*Preprocessing stage*/

  uint usedSeed = -1;
  if(params.rSeedForRun() != -1){
    usedSeed = params.rSeedForRun();
    srand(usedSeed);
  }else{
    usedSeed = time(NULL);
    srand(usedSeed);
  }

  Stopwatch swatch;
  swatch.set_mode(REAL_TIME);
  swatch.start("Colorspace");

  Image I(rgbI.convertToColorspace(params.colorspace()));

  swatch.stop("Colorspace");
  if(params.verbose())
    swatch.report("Colorspace");

  swatch.start("Segmentation");
  SegImage segImg(I,params.spParams());
  swatch.stop("Segmentation");
  if(params.verbose())
    swatch.report("Segmentation");

  swatch.start("Graph+Preprocessing");
  Graph graph(rgbI, segImg, params.fWeights());
  swatch.stop("Graph+Preprocessing");
  if(params.verbose())
    swatch.report("Graph+Preprocessing");

  const uint nProposals=params.nProposals();
  const uint nSps=segImg.nSps();
  std::vector<std::vector<bool> > spGroups(nProposals, std::vector<bool>(nSps,0));

  std::vector<BBox> bbProposals(nProposals, BBox());


  swatch.start("Proposal generation");

  uint nextSp=0, oSp=0;
  uint n=0, nSpsInGroup=0;
  double E0=0.0, E=0.0, nextS=0.0, Ea=0.0, groupA_double=0.0;
  uint groupA=0;
  uint xmin=0, ymin=0, xmax=0, ymax=0;
  IntTree T(nSps);
  for( uint k=0; k<nProposals; k++){

    nextSp=floor((rand()%nSps)+0.5);//Round

    assert(nextSp>=0 && nextSp<nSps && "Bad seed");
    assert(k < spGroups.size());
    assert(nextSp < spGroups.at(k).size());
    spGroups.at(k).at(nextSp)=1;

    nSpsInGroup=1;
    groupA_double=segImg.normArea(nextSp);
    groupA = floor(groupA_double*65535+0.5);

    if(nSpsInGroup==nSps)
      continue;

    std::vector<std::pair<uint, double> > neighs= graph.getNOfNode(nextSp);

    std::vector<IntTree::Node> ns;     
    for(n=0; n<neighs.size(); n++){
      assert(n < neighs.size());
      double e=neighs.at(n).second;
      uint i=MAX(neighs.at(n).first,nextSp);
      uint j=MIN(neighs.at(n).first,nextSp);
      ns.push_back(IntTree::Node(e,i,j,std::vector<double>::iterator(NULL)));
      T.AddNode(ns.back());
    }

    assert(T.AreWConsistent());

    E0=2.0*Unif01();
    while(1){

      assert(T.AreWConsistent());

      IntTree::Node nextNode(T.SampleNode(Unif01()));

      assert(k < spGroups.size());
      assert(nextNode.i() < spGroups.at(k).size());
      if(spGroups.at(k).at(nextNode.i())){
        nextSp=nextNode.j();
        oSp=nextNode.i();
      }else{
        assert(k < spGroups.size());
        assert(nextNode.j() < spGroups.at(k).size());
        assert(spGroups.at(k).at(nextNode.j()));
        nextSp=nextNode.i();
        oSp=nextNode.j();
      }
      nextS=nextNode.e();

      Ea=params.alpha(groupA);
      E=Ea+1.0-nextS;
      assert(E>=0 && E<=2.0);

      if(E>E0){
        break;
      }else{
        assert(k < spGroups.size());
        assert(nextSp < spGroups.at(k).size());

        spGroups.at(k).at(nextSp)=1;
        nSpsInGroup++;

        if(nSpsInGroup==nSps) {
          break;
        }

        groupA_double += segImg.normArea(nextSp);
        groupA = floor(groupA_double*65535+0.5);

        std::vector<std::pair<uint, double> > N(graph.getNOfNode(nextSp));

        for(n=0;n<N.size();n++){
          assert(n < N.size());
          uint j=N.at(n).first;
          assert(k < spGroups.size());
          assert(j < spGroups.at(k).size());
          if(spGroups.at(k).at(j)){
            T.RemoveNode(MAX(nextSp,j),MIN(nextSp,j));

            assert(T.AreWConsistent());
          }else{
            assert(n < N.size());
            T.AddNode(IntTree::Node(N.at(n).second,MAX(nextSp,j),MIN(nextSp,j),std::vector<double>::iterator(NULL)));
            assert(T.AreWConsistent());
          }
        }
      }

    }

    /*Compute bounding box*/

    xmin=UINT_MAX;
    ymin=UINT_MAX;
    xmax=0;
    ymax=0;
    for(uint s=0;s<nSps;s++){
      assert(k < spGroups.size());
      assert(s < spGroups.at(k).size());
      if(spGroups.at(k).at(s)){
        const BBox& bb=segImg.bbox(s);
        if(xmin>bb.jMin){
          xmin=bb.jMin;
        }
        if(ymin>bb.iMin){
          ymin=bb.iMin;
        }
        if(xmax<bb.jMax){
          xmax=bb.jMax;
        }
        if(ymax<bb.iMax){
          ymax=bb.iMax;
        }
      }
    }

    assert(k < bbProposals.size());
    bbProposals.at(k).jMin=xmin;
    bbProposals.at(k).iMin=ymin;
    bbProposals.at(k).jMax=xmax;
    bbProposals.at(k).iMax=ymax;

    T.Reset();
  }


  swatch.stop("Proposal generation");

  if(params.verbose())
    swatch.report("Proposal generation");

  assert(bbProposals.size()==nProposals);

  return bbProposals;

}

#endif
