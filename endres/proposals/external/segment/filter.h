/*
Copyright (C) 2006 Pedro Felzenszwalb

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
*/

/* simple filters */

#ifndef FILTER_H
#define FILTER_H

#include <vector>
#include <cmath>
#include "image.h"
#include "misc.h"
#include "convolve.h"
#include "imconv.h"

#define WIDTH 4.0

/* normalize mask so it integrates to one */
static void normalize(std::vector<double> &mask) {
  int len = mask.size();
  double sum = 0;
  for (int i = 1; i < len; i++) {
    sum += fabs(mask[i]);
  }
  sum = 2*sum + fabs(mask[0]);
  for (int i = 0; i < len; i++) {
    mask[i] /= sum;
  }
}

/* make filters */
#define MAKE_FILTER(name, fun)                                \
static std::vector<double> make_ ## name (double sigma) {       \
  sigma = std::max(sigma, (double)0.01F);			      \
  int len = (int)ceil(sigma * WIDTH) + 1;                     \
  std::vector<double> mask(len);                               \
  for (int i = 0; i < len; i++) {                             \
    mask[i] = fun;                                            \
  }                                                           \
  return mask;                                                \
}

MAKE_FILTER(fgauss, exp(-0.5*square(i/sigma)));

/* convolve image with gaussian filter */
static image<double> *smooth(image<double> *src, double sigma) {
  std::vector<double> mask = make_fgauss(sigma);
  normalize(mask);

  image<double> *tmp = new image<double>(src->height(), src->width(), false);
  image<double> *dst = new image<double>(src->width(), src->height(), false);
  convolve_even(src, tmp, mask);
  convolve_even(tmp, dst, mask);

  delete tmp;
  return dst;
}

/* convolve image with gaussian filter */
image<double> *smooth(image<uchar> *src, double sigma) {
  image<double> *tmp = imageUCHARtoDOUBLE(src);
  image<double> *dst = smooth(tmp, sigma);
  delete tmp;
  return dst;
}

/* compute laplacian */
static image<double> *laplacian(image<double> *src) {
  int width = src->width();
  int height = src->height();
  image<double> *dst = new image<double>(width, height);  

  for (int y = 1; y < height-1; y++) {
    for (int x = 1; x < width-1; x++) {
      double d2x = imRef(src, x-1, y) + imRef(src, x+1, y) -
	2*imRef(src, x, y);
      double d2y = imRef(src, x, y-1) + imRef(src, x, y+1) -
	2*imRef(src, x, y);
      imRef(dst, x, y) = d2x + d2y;
    }
  }
  return dst;
}

#endif
