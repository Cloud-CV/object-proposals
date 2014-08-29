#ifndef IMAGE
#define IMAGE

#include <vector>
#include <assert.h>
#include <string>
#include <math.h>
#include "params.h"

#define MIN3(x,y,z)  ((y) <= (z) ? \
                         ((x) <= (y) ? (x) : (y)) \
                     : \
                         ((x) <= (z) ? (x) : (z)))

#define MAX3(x,y,z)  ((y) >= (z) ? \
                         ((x) >= (y) ? (x) : (y)) \
                     : \
                         ((x) >= (z) ? (x) : (z)))

typedef unsigned int uint;
typedef unsigned char uchar;

class Image{

  public:

    //Image(const std::string& filename);//Removed to avoid opencv dependencies

    Image(const std::vector<uint> dims, const uint val, const Colorspace colorspace);

    Image(const uchar * const I, const std::vector<uint> dims, const Colorspace colorspace);

    inline uint h() const{return h_;}
    inline uint w() const{return w_;}
    inline uint c() const{return c_;}
    inline std::vector<uint> imgSize() const{return imgSize_;}

    inline uint at(const uint i, const uint j, const uint k ) const{return I_.at(i).at(j).at(k);};

    Image convertToColorspace(const Colorspace colorspace) const;

  protected:

    uint h_;
    uint w_;
    uint c_;
    std::vector<uint> imgSize_;
    Colorspace colorspace_;
    std::vector<std::vector<std::vector<uchar> > > I_;
};

Image::Image(const uchar * const I, const std::vector<uint> dims, const Colorspace colorspace):colorspace_(colorspace){
  assert(dims.size()==3);
  assert(dims.at(2)==3);

  h_=dims.at(0);
  w_=dims.at(1);
  c_=dims.at(2);

  imgSize_=dims;

  I_.resize(h_);

  for(uint i=0; i<h_; i++){
    I_.at(i).resize(w_);
    for(uint j=0; j<w_; j++){
      I_.at(i).at(j).resize(c_);
      for(uint k=0; k<c_; k++){
        I_.at(i).at(j).at(k)=I[i+j*h_+k*h_*w_];
      }
    }
  }
}

Image::Image(const std::vector<uint> dims, const uint val, const Colorspace colorspace):colorspace_(colorspace){
  assert(dims.size()==3);
  assert(dims.at(2)==3);

  I_.resize(dims.at(0),std::vector<std::vector<uchar> >(dims.at(1), std::vector<uchar>(dims.at(2),val)));
  imgSize_=dims;
  h_=dims.at(0);
  w_=dims.at(1);
  c_=dims.at(2);
}

inline double f(const double t){
  if(t>0.008856){
    return pow(t,0.33333333);
  }else{
    return (7.787*t+0.137931);
  }
}

Image Image::convertToColorspace(const Colorspace colorspace) const{

  Image convI(imgSize_,0, colorspace);

  if(this->colorspace_==RGB && colorspace==rg)
  {
    uint RGB = 0;
    uchar R=0, G=0, B=0;
    for(uint i=0; i<h_; i++){
      for(uint j=0; j<w_; j++){
        R=this->at(i,j,0);
        G=this->at(i,j,1);
        B=this->at(i,j,2);
        RGB=R+G+B;
        convI.I_.at(i).at(j).at(0)=(uchar) (255.0*(float)R/(float)RGB);
        convI.I_.at(i).at(j).at(1)=(uchar) (255.0*(float)G/(float)RGB);
        convI.I_.at(i).at(j).at(2)=(uchar) (RGB/3.0);
      }
    }
  }else if(this->colorspace_==RGB && colorspace==LAB){

    const Image& rgbI=*this;
    Image& labI=convI;

    const uint  h=rgbI.h(),w=rgbI.w();

    double r,g,b,x,y,z,L,A,B,fx,fy,fz,delta;
    for(uint i=0; i<h; i++){
      for(uint j=0; j<w; j++){

        r=rgbI.at(i,j,0)/255.0;
        g=rgbI.at(i,j,1)/255.0;
        b=rgbI.at(i,j,2)/255.0;

        //rgbI to XYZ

        x=0.412453*r+0.357580*g+0.180423*b;
        y=0.212671*r+0.715160*g+0.072169*b;
        z=0.019334*r+0.119193*g+0.950227*b;

        //xyz to L*A*B*

        x/=0.950456;
        z/=1.088754;

        if(y>0.008856){
          L=116.0*pow(y,0.333333333)-16.0;
        }else{
          L=903.3*y;
        }

        fx=f(x);
        fy=f(y);
        fz=f(z);

        A=500.0*(fx-fy)+delta;
        B=200.0*(fy-fz)+delta;

        assert(L>=0.0 && L<=100.0 && -127.0<=A && A<=127.0 && -127.0<=B && B<=127.0);

        //Conversion to matlab-like result:

        L*=2.55;//255/100
        A+=128.0;
        B+=128.0;

        assert(L>=0.0 && L<=255.0 && 0.0<=A && A<=255.0 && 0.0<=B && B<=255.0);

        labI.I_.at(i).at(j).at(0)=round(L);
        labI.I_.at(i).at(j).at(1)=round(A);
        labI.I_.at(i).at(j).at(2)=round(B);
      }
    }
  }else if(this->colorspace_==RGB && colorspace==HSV){
    const Image& rgbI=*this;
    Image& hsvI=convI;

    double r,g,b,h,s,v, rgb_min, rgb_max;
    for(uint i=0; i<rgbI.h(); i++){
      for(uint j=0; j<rgbI.w(); j++){
        r=rgbI.at(i,j,0)/255.0;
        g=rgbI.at(i,j,1)/255.0;
        b=rgbI.at(i,j,2)/255.0;

        rgb_min = MIN3(r, g, b);
        rgb_max = MAX3(r, g, b);
        v = rgb_max;
        if (v == 0) {
          h = s = 0;
        }else{
          /* Normalize value to 1 */
          r /= v;
          g /= v;
          b /= v;
          rgb_min = MIN3(r, g, b);
          rgb_max = MAX3(r, g, b);
          s = rgb_max - rgb_min;
          if (s == 0) {
            h = 0;
          }else{
            /* Normalize saturation to 1 */
            r = (r - rgb_min)/(rgb_max - rgb_min);
            g = (g - rgb_min)/(rgb_max - rgb_min);
            b = (b - rgb_min)/(rgb_max - rgb_min);
            rgb_min = MIN3(r, g, b);
            rgb_max = MAX3(r, g, b);
            /* Compute hue */
            if (rgb_max == r) {
              h = 0.0 + 60.0*(g - b);
              if (h < 0.0) {
                h += 360.0;
              }
            } else if (rgb_max == g) {
              h = 120.0 + 60.0*(b - r);
            } else /* rgb_max == b */ {
              assert(rgb_max==b);
              h = 240.0 + 60.0*(r - g);
            }
          }
        }

        hsvI.I_.at(i).at(j).at(0)=(uchar) round(h/360.0*255.0);
        hsvI.I_.at(i).at(j).at(1)=(uchar) round(255.0*s);
        hsvI.I_.at(i).at(j).at(2)=(uchar) round(255.0*v);

        assert(0<=hsvI.I_.at(i).at(j).at(0) && hsvI.I_.at(i).at(j).at(0)<=255);
        assert(0<=hsvI.I_.at(i).at(j).at(1) && hsvI.I_.at(i).at(j).at(1)<=255);
        assert(0<=hsvI.I_.at(i).at(j).at(2) && hsvI.I_.at(i).at(j).at(2)<=255);

      }
    }

  }else if(this->colorspace_==RGB && colorspace==Opponent){
    //Evaluating Color Descriptors for Object and Scene Recognition
    
    const Image& rgbI=*this;
    Image& oppI=convI;

    std::vector< std::vector< std::vector<double> > > tempI(rgbI.h(), std::vector< std::vector<double> >(rgbI.w(), std::vector<double>(3,0.0)));

    double r, g, b, o1, o2, o3;
    for(uint i=0; i<rgbI.h(); i++){
      for(uint j=0; j<rgbI.w(); j++){

        r=(double) rgbI.at(i,j,0);
        g=(double) rgbI.at(i,j,1);
        b=(double) rgbI.at(i,j,2);

        tempI.at(i).at(j).at(0)=(r-g)/sqrt(2);
        tempI.at(i).at(j).at(1)=(r+g-2*b)/sqrt(6);
        tempI.at(i).at(j).at(2)=(r+g+b)/sqrt(3);
      }
    }

    //Normalization
    double minO1= DBL_MAX, minO2=DBL_MAX, minO3=DBL_MAX, maxO1= -DBL_MAX, maxO2=-DBL_MAX, maxO3=-DBL_MAX ;
    for(uint i=0; i<rgbI.h(); i++){
      for(uint j=0; j<rgbI.w(); j++){

        if(tempI.at(i).at(j).at(0)<minO1){
          minO1=tempI.at(i).at(j).at(0);
        }
        if(tempI.at(i).at(j).at(1)<minO2){
          minO2=tempI.at(i).at(j).at(1);
        }
        if(tempI.at(i).at(j).at(2)<minO3){
          minO3=tempI.at(i).at(j).at(2);
        }

        if(tempI.at(i).at(j).at(0)>maxO1){
          maxO1=tempI.at(i).at(j).at(0);
        }
        if(tempI.at(i).at(j).at(1)>maxO2){
          maxO2=tempI.at(i).at(j).at(1);
        }
        if(tempI.at(i).at(j).at(2)>maxO3){
          maxO3=tempI.at(i).at(j).at(2);
        }
      }
    }

    //Scale from 0 to 255
    double diffO1=maxO1-minO1;
    double diffO2=maxO2-minO2;
    double diffO3=maxO3-minO3;

    for(uint i=0; i<rgbI.h(); i++){
      for(uint j=0; j<rgbI.w(); j++){
        assert(minO1<=tempI.at(i).at(j).at(0) && tempI.at(i).at(j).at(0)<=maxO1);
        assert(minO2<=tempI.at(i).at(j).at(1) && tempI.at(i).at(j).at(1)<=maxO2);
        assert(minO3<=tempI.at(i).at(j).at(2) && tempI.at(i).at(j).at(2)<=maxO3);

        oppI.I_.at(i).at(j).at(0)=uchar((tempI.at(i).at(j).at(0)-minO1)/diffO1*255.0);
        oppI.I_.at(i).at(j).at(1)=uchar((tempI.at(i).at(j).at(1)-minO2)/diffO2*255.0);
        oppI.I_.at(i).at(j).at(2)=uchar((tempI.at(i).at(j).at(2)-minO3)/diffO3*255.0);
      }
    }

  }else{

    printf("this->colorspace_:%d colorspace:%d\n",this->colorspace_,colorspace);
    printf("RGB:%d\n",RGB);
    printf("rg:%d\n",rg);
    printf("LAB:%d\n",LAB);

    printf("Error: Unknown combination of colorspaces\n");

    exit(-1);

  }

  return convI;
}

//Image::Image(const std::string& filename){
//
//  //Load image:
//  cv::Mat cvI;
//  cvI = cv::imread(filename, CV_LOAD_IMAGE_COLOR);
//  if(!cvI.data )
//  {
//    std::cout <<  "Could not open or find the image" << std::endl ;
//    exit(-1);
//  }
//
//  //Adapt to class
//  h_=cvI.rows;
//  assert(h_>0);
//
//  w_=cvI.cols;
//  assert(w_>0);
//
//  c_=3; //We know this because we specified: CV_LOAD_IMAGE_COLOR
//
//  imgSize_= std::vector<uint>( 3, 0);
//  imgSize_.at(0) = h_; imgSize_.at(1) = w_; imgSize_.at(2) = c_;
//
//  colorspace_=RGB; //We assume image was saved in RGB space
//
//  I_.resize(h_);
//  uint8_t* pixelPtr = (uint8_t*)cvI.data;
//  uint r = 0, g = 0, b = 0;
//  for(uint i=0; i<h_; i++){
//    I_.at(i).resize(w_);
//    for(uint j=0; j<w_; j++){
//      I_.at(i).at(j).resize(c_);
//      for(uint k=0; k<c_; k++){
//        I_.at(i).at(j).at(2) = pixelPtr[i*w_*3 + j*3]; // B
//        I_.at(i).at(j).at(1) = pixelPtr[i*w_*3 + j*3 + 1]; // G
//        I_.at(i).at(j).at(0) = pixelPtr[i*w_*3 + j*3 + 2]; // R
//      }
//    }
//  }
//}


#endif













