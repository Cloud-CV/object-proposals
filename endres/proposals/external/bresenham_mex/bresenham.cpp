/********************************************************************
	created:	2006/08/04
	created:	4:8:2006   19:15
	file base:	bresenham
	file ext:	cpp
	author:		孙鹏
	
	purpose:	给定线段的两个端点,给出中间的所有点
*********************************************************************/
#include "bresenham.h"

#ifdef _DEBUG
#include <iostream>
#endif // _DEBUG

// 为防止代码膨胀，自己写的辅助函数
namespace {
  namespace my {
  
    inline int max(int a,int b) { // rather than std::max ...
      return ((a > b) ? a : b);
    }
    inline int abs(int a) {
      return ( (a >= 0) ? a : (-a) );
    }
  } // namespace my

}


int bresenham(int rs, int cs, int re, int ce, int* rr, int* cc)
{
  //
  // [1]中针对0<m<1的情形给出了讲解，由此可总结出一般的步骤：
  //
  // 1.当|m|<1时
  //   决策变量满足
  //      _
  //     /  p0   = IncreY*2*Dy - IncreX*Dx                  k = 0
  //    |
  //     \_ pk+1 = pk + (2*Dy*Sx - 2*Dx*Sy)*IncreX*IncreY   k > 0 
  // 
  //   其中，IncreX - 自己推导后引入的控制因子，增加时取1，否则-1
  //         IncreY - 自己推导后引入的控制因子，y增加时取1，否则-1
  //         Sx - 在x方向上的步进量,{1,-1}
  //         Sy - 在y方向上的步进量,{0,IncreY}
  //   于是有：
  //   若pk < 0，Sy = 0;否则Sy = IncreY
  //   下一个待画点总是（xk+Sx, yk+Sy），且pk总满足上面的递归式
  //   进行Dx次，总共求出Dx+1个“点对”
  // 
  // 2.当|m|>1时，由对称性，只需将1.中所有的x,y反过来。
  //
  // 注意！！
  // x对应列（col），y对应行（row）!!
  //
  int p = 0;
  int IncreX = 0, IncreY = 0;
  int Sx = 0, Sy = 0;
  int Dx, Dy;
  Dx = ce - cs;
  Dy = re - rs;
#ifdef _DEBUG
  std::cout << "x0 = " << cs << ", "
    << "y0 = " << rs << std::endl;
  std::cout << "x1 = " << ce << ", "
    << "y1 = " << re << std::endl;
  std::cout << "Dx = " << Dx << ", " 
    << "Dy = " << Dy << std::endl;
#endif // _DEBUG

  if (my::abs(Dy) <= my::abs(Dx)) { // |m| <= 1
    if (ce > cs) Sx = 1, IncreX = 1;
    else Sx = -1, IncreX = -1;
    if (re > rs) IncreY = 1;
    else IncreY = -1;
    int totalLen = my::abs(Dx) + 1;

#ifdef _DEBUG
    std::cout << "Sx = " << Sx << std::endl;
    std::cout << "Incre = " << IncreX << std::endl;
    std::cout << std::endl;
#endif // _DEBUG

    for (int i = 0; i < totalLen; ++i ) {
      if (i == 0) {
        *(cc+i) = cs;
        *(rr+i) = rs;
        p = IncreY*2*Dy - IncreX*Dx;
      }
      else { // i > 0
        if (p < 0) Sy = 0;
        else Sy = IncreY;
        *(cc+i) = *(cc+i-1) + Sx;
        *(rr+i) = *(rr+i-1) + Sy;
        p += (2*Dy*Sx - 2*Dx*Sy)*IncreX*IncreY;
      }

#ifdef _DEBUG
      std::cout << "(" << *(cc+i) << ", " << *(rr+i) << ") " << std::endl;
      std::cout << "p = " << p <<  ", " << "Sy = " << Sy << std::endl;
      std::cout << std::endl;
#endif // _DEBUG
    
    }
    return totalLen;
  }
  else { // |m| > 1 :只需反转所有的x,y
    return bresenham(cs, rs, ce, re, cc, rr);
  }


}



int bresenham_len(int rs, int cs, int re, int ce)
{
  return my::max(my::abs(re-rs), my::abs(ce-cs)) + 1;
}