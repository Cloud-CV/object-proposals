#ifndef PARAMS
#define PARAMS

#include <vector>
#include <assert.h>
#include <string.h>
#include "helper.h"

typedef unsigned int uint;
typedef unsigned char uchar;


enum Colorspace { RGB, rg, LAB, Opponent, HSV};

class Params {

  public:

    Params(){};

    struct SpParams{
      double sigma_;
      double c_;
      double min_size_;
    };

    struct FWeights{
      double wBias_;
      double wCommonBorder_;
      double wLABColorHist_;
      double wSizePer_;
    };

    inline Colorspace colorspace() const {return colorspace_;}
    inline SpParams spParams() const {return spParams_;}
    inline FWeights fWeights() const {return fWeights_;}
    inline uint nProposals() const {return nProposals_;};
    inline double alpha(const uint i) const {return alpha_.at(i);};
    inline int rSeedForRun() const {return rSeedForRun_;};
    inline bool verbose() const{return verbose_;}

    void setNProposals( const uint rhs){nProposals_=rhs;};
    void setColorspace( const Colorspace rhs){colorspace_=rhs;};
    void setSpParams(const SpParams& rhs){spParams_=rhs;};
    void setAlpha(const std::vector<double>& rhs){alpha_=rhs;};
    void setFWeights(const FWeights& rhs){fWeights_=rhs;};
    void setRSeedForRun(const int rhs) {rSeedForRun_ = rhs;};
    void setVerbose(const bool rhs) {verbose_ = rhs;};

  private:

    uint nProposals_;
    Colorspace colorspace_;
    SpParams spParams_;
    std::vector<double> alpha_;
    FWeights fWeights_;
    int rSeedForRun_; //-1 means no random seed
    bool verbose_;
};
#endif

