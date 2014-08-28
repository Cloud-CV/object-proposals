#include <math.h>
#include <sys/types.h>
#include "mex.h"
#include <misc.h>
#include <pnmfile.h>

#include <iostream>
#include <stdio.h>
#include <cstdlib>
#include <vector>
#include "image.h"
#include "misc.h"
#include "filter.h"
#include "segment-graph.h"

// dissimilarity measure between pixels
static inline double diff(image<double> *r, image<double> *g, image<double> *b,
			 int x1, int y1, int x2, int y2) {
  return sqrt(square(imRef(r, x1, y1)-imRef(r, x2, y2)) +
	      square(imRef(g, x1, y1)-imRef(g, x2, y2)) +
	      square(imRef(b, x1, y1)-imRef(b, x2, y2)));
}

void segment_image_mex(double *im, double *out, int height, int width, double sigma, double c, int min_size, int *num_ccs) {

  std::cout<<"Processing a "<<height<<" x " << width<< " image with sigma="<<sigma<<", c="<<c<<", and min size="<<min_size<<std::endl;
  image<double> *r = new image<double>(width, height);
  image<double> *g = new image<double>(width, height);
  image<double> *b = new image<double>(width, height);

  // smooth each color channel  
  for (int y = 0; y < height; y++) {
   for (int x = 0; x < width; x++) {
      imRef(r, x, y) = im[x*height + y]; //imRef(im, x, y).r;
      imRef(g, x, y) = im[width*height + x*height + y];//imRef(im, x, y).g;
      imRef(b, x, y) = im[2*width*height + x*height +y]; //imRef(im, x, y).b;
    }
  }
  image<double> *smooth_r = smooth(r, sigma);
  image<double> *smooth_g = smooth(g, sigma);
  image<double> *smooth_b = smooth(b, sigma);
  delete r;
  delete g;
  delete b;
 
  // build graph
  edge *edges = new edge[width*height*4];
  int num = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (x < width-1) {
	edges[num].a = y * width + x;
	edges[num].b = y * width + (x+1);
	edges[num].w = diff(smooth_r, smooth_g, smooth_b, x, y, x+1, y);
	num++;
      }

      if (y < height-1) {
	edges[num].a = y * width + x;
	edges[num].b = (y+1) * width + x;
	edges[num].w = diff(smooth_r, smooth_g, smooth_b, x, y, x, y+1);
	num++;
      }

      if ((x < width-1) && (y < height-1)) {
	edges[num].a = y * width + x;
	edges[num].b = (y+1) * width + (x+1);
	edges[num].w = diff(smooth_r, smooth_g, smooth_b, x, y, x+1, y+1);
	num++;
      }

      if ((x < width-1) && (y > 0)) {
	edges[num].a = y * width + x;
	edges[num].b = (y-1) * width + (x+1);
	edges[num].w = diff(smooth_r, smooth_g, smooth_b, x, y, x+1, y-1);
	num++;
      }
    }
  }
  delete smooth_r;
  delete smooth_g;
  delete smooth_b;

  // segment
  universe *u = segment_graph(width*height, num, edges, c);
  
  // post process small components
  for (int i = 0; i < num; i++) {
    int a = u->find(edges[i].a);
    int b = u->find(edges[i].b);
    if ((a != b) && ((u->size(a) < min_size) || (u->size(b) < min_size)))
      u->join(a, b);
  }
  delete [] edges;
  *num_ccs = u->num_sets();

  double *ind_map = new double[width*height];
  for (int i = 0; i < width*height; i++)
     ind_map[i] = -1;

  double cur_ind = 1;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int comp = u->find(y * width + x);
      if(ind_map[comp]==-1) {
         ind_map[comp] = cur_ind;
         cur_ind++;
      }
      out[height*x + y] = ind_map[comp];
    }
  }  

  delete u;
  delete [] ind_map;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs < 4)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 1)
    mexErrMsgTxt("Wrong number of outputs");
  if (mxGetNumberOfDimensions(prhs[0]) != 3) {
    mexErrMsgTxt("Needs to be a color image!");
  }
    
  const int *dims = mxGetDimensions(prhs[0]);
  
  if(dims[2]!=3) {
    mexErrMsgTxt("Needs to be a color image!");
  }

//  image<rgb> *seg = segment_image(input, sigma, k, min_size, &num_ccs); 



  double *im = (double *)mxGetPr(prhs[0]);
  double *sigma = (double *)mxGetPr(prhs[1]);
  double *c = (double *)mxGetPr(prhs[2]);
  double *min_size = (double *)mxGetPr(prhs[3]);

  int min_size_int = (int)(*min_size);
  
  mxArray *mx_output = mxCreateNumericMatrix(dims[0], dims[1], mxDOUBLE_CLASS, mxREAL);
  double *output = (double *)mxGetPr(mx_output);

  int num_ccs;
  segment_image_mex(im, output, dims[0], dims[1], *sigma, *c, min_size_int, &num_ccs);
   std::cout<<"uff..."<<num_ccs<<std::endl;
  plhs[0] = mx_output;
}

