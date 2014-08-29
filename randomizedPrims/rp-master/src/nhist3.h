#ifndef NHIST3_H
#define NHIST3_H

class NHist3{

  public:
    NHist3(const Image& labI, const PixelList& pl, const uint nBins);
    double Intersect(const NHist3& nh) const;

  private:
    std::vector<std::vector<std::vector<double> > > h_;
    uint nBins_;
    double inc_;

    inline uint CalcBin(const uchar val) const;
};

NHist3::NHist3(const Image& labI, const PixelList& pl, const uint nBins):nBins_(nBins){
  h_.resize(nBins_, std::vector<std::vector<double> >(nBins_, std::vector<double>(nBins_,0.0)));

#ifndef NDEBUG
  for(uint i=0; i<nBins_;i++){
    for(uint j=0; j<nBins_;j++){
      for(uint k=0; k<nBins_;k++){
        assert(std::abs(h_.at(i).at(j).at(k))<5E-5);
      }
    }
  }
#endif

  inc_=256/nBins_;

  uint b0=0, b1=0, b2=0, i=0, j=0;
  for(uint k=0; k<pl.size();k++){
    i=pl.at(k).first;
    j=pl.at(k).second;
    b0=CalcBin(labI.at(i,j,0));
    b1=CalcBin(labI.at(i,j,1));
    b2=CalcBin(labI.at(i,j,2));
    h_.at(b0).at(b1).at(b2)+=1.0;
  }

  //Normalize
  const uint Z=pl.size();
  for(uint i=0; i<nBins_;i++){
    for(uint j=0; j<nBins_;j++){
      for(uint k=0; k<nBins_;k++){
        h_.at(i).at(j).at(k)/=Z;
        assert(h_.at(i).at(j).at(k)>=0.0 && h_.at(i).at(j).at(k)<=1.0);
      }
    }
  }
}

inline uint NHist3::CalcBin(const uchar val) const{
  uint bin=std::floor(val/inc_);
  if(bin==nBins_){
    bin-=1;
  }
  return bin;
}

double NHist3::Intersect(const NHist3& nh) const{
  assert(nBins_==nh.nBins_);
  double s=0.0;
  for(uint i=0; i<nBins_;i++){
    for(uint j=0; j<nBins_;j++){
      for(uint k=0; k<nBins_;k++){
        s+=std::min(this->h_.at(i).at(j).at(k),nh.h_.at(i).at(j).at(k));
      }
    }
  }
  assert(s>=0.0 && s<=1.0);
  return s;
}

#endif
