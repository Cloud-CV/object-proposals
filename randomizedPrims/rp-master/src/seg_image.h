#ifndef SEG_IMAGE
#define SEG_IMAGE

#include <vector>
#include <assert.h>
#include <string>
#include <limits.h>
#include "params.h"
#include "image.h"
#include "FelzenSegment/segment-image.h"
#include "FelzenSegment/segment_image_index.h"
#include "FelzenSegment/image.h"

typedef std::vector<std::pair<uint, uint> > PixelList;
typedef std::pair<uint, uint> PixCoords;

//BBox in C++ coordinates (starts from 0)
class BBox{   
  public:
  uint jMin;
  uint iMin;
  uint jMax;
  uint iMax;
  BBox(){
    jMin=UINT_MAX;
    iMin=UINT_MAX;
    jMax=0;
    iMax=0;
  };
  bool IsConsistent() const{
    return (iMin<=iMax) && (jMin<=jMax);
  };
};

class SegImage{
  public:
    SegImage(const Image& I, const Params::SpParams& spParams);
    inline uint h() const{return h_;}
    inline uint w() const{return w_;}
    inline uint c() const{return c_;}
    inline std::vector<uint> imgSize() const{return imgSize_;}
    inline uint at(const uint i, const uint j) const{return I_.at(i).at(j);};
    inline uint nSps() const{return nSps_;};
    inline double normArea(const uint i) const{return spInfo_.normAreas_.at(i);}
    inline uint normArea16b(const uint i) const{return spInfo_.normAreas16b_.at(i);}

    inline std::vector< std::vector<uint> > coMatrix() const{return spInfo_.coMatrix_;};

    inline uint perimeter(const uint i) const{return spInfo_.perimeters_.at(i);};
    inline PixelList pixelList(const uint i) const{return spInfo_.pixelLists_.at(i);};
    inline BBox bbox(const uint i) const{return spInfo_.bbs_.at(i);};

    class SpInfo{
      friend class SegImage;
      private:
      std::vector<PixelList > pixelLists_; //List of pixels of each sp
      std::vector< std::vector<uint> > coMatrix_; //Coocurrence matrix (diagonal included)
      std::vector<uint> perimeters_;
      std::vector<BBox> bbs_;
      std::vector<uint> nPixels_;
      std::vector<double> normAreas_;
      std::vector<uint> normAreas16b_;
    };

  private:

    std::vector<std::vector<uint> > I_; //indexes (from 0 to nSps_-1)
    uint nSps_;
    uint h_;
    uint w_;
    uint c_;
    std::vector<uint> imgSize_;

    void ExtractSpInfo();

    uint FindMinValue() const;
    uint FindMaxValue() const;

    SpInfo spInfo_;
};

SegImage::SegImage(const Image& I, const Params::SpParams& spParams){

  const std::vector<uint>& dims=I.imgSize();

  imgSize_=dims;
  h_=dims.at(0);
  w_=dims.at(1);
  c_=dims.at(2);

  rgb pixel={0,0,0};

  //Convert to F format
  image<rgb> im_rgb(w_, h_, true);
  for(uint i=0; i<h_;i++){
    for(uint j=0; j<w_;j++){
      pixel.r=I.at(i,j,0);
      pixel.g=I.at(i,j,1);
      pixel.b=I.at(i,j,2);
      im_rgb.data[i*w_+j]=pixel;
    }
  }

  int num_ccs;

  //image<rgb> * seg_img_rgb = segment_image(&im_rgb, spParams.sigma_, spParams.c_, spParams.min_size_, &num_ccs);

  double * seg_img_idx=segment_image_index(&im_rgb, spParams.sigma_, spParams.c_, spParams.min_size_, &num_ccs);

  assert(num_ccs>0);

  nSps_=num_ccs;

  //Convert F to my Image format
  I_.resize(h_,std::vector<uint>(w_,6666));

#ifndef NDEBUG
  double dummy=0.0;
#endif
  for(uint i=0; i<h_;i++){
    for(uint j=0; j<w_;j++)
    {
      assert(fabs(modf(seg_img_idx[j*h_+i], &dummy))<5.0E-5 ); 
      assert(modf(seg_img_idx[j*h_+i], &dummy)>-5.0E-5);

      I_.at(i).at(j)=(uint)seg_img_idx[j*h_+i]-1; //Horizontal indexing! -1 to index to 0 to nSps-1
    }
  }

  assert(this->FindMinValue()==0);
  assert(this->FindMaxValue()==(nSps_-1));

  this->ExtractSpInfo();
}


uint SegImage::FindMaxValue() const{

  uint max=0, cur=0; 

  for(uint i=0;i<h_;i++){
    for(uint j=0; j<w_;j++){
      cur=this->at(i,j);
      assert(cur>=0);
      if(cur>max){
        max=cur;
      }
    }
  }

  return max;

}

uint SegImage::FindMinValue() const{

  uint min=UINT_MAX, cur=0; 

  for(uint i=0;i<h_;i++){
    for(uint j=0; j<w_;j++){
      cur=this->at(i,j);
      assert(cur>=0);
      if(cur<min){
        min=cur;
      }
    }
  }

  return min;

}

void SegImage::ExtractSpInfo(){

  std::vector<PixelList >& pl=spInfo_.pixelLists_;
  std::vector< std::vector<uint> >& coMat=spInfo_.coMatrix_;

  pl.resize(nSps_);
  coMat.resize(nSps_,std::vector<uint>(nSps_,0));

  //Populate pixel lists and bbs
  std::vector<BBox>& bbs= spInfo_.bbs_;
  bbs.resize(nSps_);
  uint pid=0;
  for(uint i=0;i<h_;i++){
    for(uint j=0;j<w_;j++){      
      pid=I_.at(i).at(j);
      pl.at(pid).push_back(PixCoords(i,j));

      //Update bb of pid      
      if(bbs.at(pid).iMin > i){
        bbs.at(pid).iMin = i;
      }
      if(bbs.at(pid).jMin > j){
        bbs.at(pid).jMin = j;
      }
      if(bbs.at(pid).iMax < i){
        bbs.at(pid).iMax = i;
      }
      if(bbs.at(pid).jMax < j){
        bbs.at(pid).jMax = j;
      }
    }
  }

#ifndef NDEBUG
  for(uint i=0; i<nSps_; i++){
    assert(bbs.at(i).IsConsistent());
  }
#endif

  //Compute coocurrence matrix
  uint npid=0;
  for(uint i=1;i<(h_-1);i++){
    for(uint j=1;j<(w_-1);j++){      
      pid=I_.at(i).at(j);

      npid=I_.at(i-1).at(j);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i+1).at(j);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i).at(j-1);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i).at(j+1);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i-1).at(j-1);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i-1).at(j+1);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i+1).at(j-1);
      coMat.at(pid).at(npid)+=1;
      npid=I_.at(i+1).at(j+1);
      coMat.at(pid).at(npid)+=1;
    }
  }



  uint sum2=0;
  for(uint i=1; i<coMat.size();i++){
    for(uint j=0; j<i;j++){
      assert(i>j);//Lower triangle (without diagonal)

      sum2=(coMat.at(i).at(j)+coMat.at(j).at(i))/2; //Over 2 for repetitions (rounding error due to image border small)

      coMat.at(i).at(j)=sum2;
      coMat.at(j).at(i)=sum2;
    }
  }

#ifndef NDEBUG
  //Make sure that all sps have at least one coocurrence
  uint n=0;
  for(uint i=0;i<nSps_;i++){
    n=0;
    for(uint j=0;j<nSps_;j++){
      n+=coMat.at(i).at(j);
    }
    if(n==0){
      printf("Superpixel: %d Out of:%d\n",i,nSps_);

      printf("Real size : %d Out of:%d\n",i,nSps_);
      printf("Error! (n==0)");
      std::exit(-1);
    }
    assert(n!=0);
  }

  bool foundOne=false;
  for(uint i=0; i<coMat.size(); i++){
    foundOne=false;
    for(uint j=0; j<coMat.size(); j++){
      if(coMat.at(i).at(j)>0 && i!=j){
        foundOne=true;
      }
    }
    assert(foundOne);
  }

#endif

  //Compute perimeters
  spInfo_.perimeters_.resize(nSps_,0);
  for(uint i=0;i<nSps_;i++){
    for(uint j=0;j<nSps_;j++){
      if(i!=j){
        spInfo_.perimeters_.at(i)+=coMat.at(i).at(j);
      }
    }

    assert(spInfo_.perimeters_.at(i)!=0);
  }

  //Compute nPixels
  std::vector<uint>& np=spInfo_.nPixels_;
  np.resize(nSps_,0);
  for(uint i=0; i<nSps_;i++){
    np.at(i)=pl.at(i).size();
    assert(np.at(i)>0);
  }

  //Compute normalized areas
  std::vector<double>& na=spInfo_.normAreas_;
  std::vector<uint>& na16b=spInfo_.normAreas16b_;
  na.resize(nSps_,0.0);
  na16b.resize(nSps_,0.0);
  double imArea=w_*h_;
  for(uint i=0;i<nSps_;i++){
    na.at(i)=np.at(i)/imArea;
    na16b.at(i)=floor(na.at(i)*65536+0.5);
    assert(na.at(i)>0);
    assert(na.at(i)<=1);
  }


}

#endif











