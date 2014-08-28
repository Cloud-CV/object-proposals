/********************************************************************
	created:	2006/08/04
	created:	4:8:2006   19:04
	file ext:	h
	author:		孙鹏
	
	purpose:	给定线段的两个端点,给出中间的所有点
            算法参见[1]
*********************************************************************/
#ifndef bresenham_H_
#define bresenham_H_



 
#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// 两点连线上的所有“点对”
// rs,cs,re,ce:起点(sTART)的行,列以及终点(eND)的行,列
// *rr,*cc:线段上所有点的行、列
// 主调函数负责分配足够的空间
// 操作成功返回点的个数，失败返回-1
// 注意！！
// row对应y, col对应x.
int bresenham (int rs, int cs, int re, int ce, int* rr, int* cc);

// 两点连线上所有“点对”的个数
// rs,cs,re,ce:起点(sTART)的行,列以及终点(eND)的行,列
// 返回点对的个数
// 注意！！
// row对应y, col对应x.
int bresenham_len (int rs, int cs, int re, int ce);

#ifdef __cplusplus
}
#endif // __cplusplus


// 参考资料
//[1]《计算机图形学》，Donald Hearn等 著 蔡士杰等 译，北京：电子工业出版社
//    p.p. 45~49
#endif // bresenham_H_