/* Copyright (C) 2013 Fuxin Li

function regioninfo = superpix_regionprops(superpixel_map)
Input:
	superpixel_map: Uint-16 (short) superpixel mapping, with each number x denotes that the corresponding pixel belong to superpixel x
Output:
	Centroid, n*2 single matrix containing the centroids for each superpixel
	BoundingBox, n*4 uint16 matrix containing the bounding bound position for each superpixel
	Area, n*1 uint32 vector containing the area of each superpixel
	Perimeter, n*1 uint32 vector containing the number of pixels on the boundary for each superpixel
	SecondMoments, n*3 single matrix, the first is sum(x^2) of all the x locations in the superpixel, the second is
	                          sum(y^2) of all the y locations in the superpixel, the third is sum(x*y) of all the x and 
							  y locations in the superpixel. These are used in the computation of major/minor axis length
							  as well as eccentricity.

The algorithm will try to assume that the lower-right corner of superpixel_map contains the superpixel with the largest index,
but it will adjust if that is not true.
--*/

#include "omp.h"
#include "mex.h"
#include "math.h"
#include "time.h"
#include "float.h"
#include "stdint.h"

/* Remember, all the memories (centroid, bb, etc.) need to be set to zero (calloc) before calling this function! */
void compute_regionprops(const uint16_t *map, uint16_t height, uint16_t width, uint16_t superpix_max, float *centroid, uint16_t *bb, uint32_t *area, uint32_t *perimeter = 0, float *second_moments = 0)
{
	uint16_t i,j,k;
	uint32_t idx;
	uint16_t cur_sp;
	// Random access the smaller matrices but keep sequential access to the big map matrix
	for (i=0;i<width;i++)
	{
		// Set it here for parallelization
		idx = i * height;
		for (j=0;j<height;j++)
		{
			if (map[idx] > superpix_max)
				mexErrMsgTxt("Haven't implemented the memory reallocation step when lower-right corner is not the biggest superpixel... Need to do so!");
			cur_sp = map[idx] - 1;
			area[cur_sp]++;
			// Centroid is x first, followed by y, use MATLAB convention for centroid computation hence i+1
			centroid[cur_sp] += i+1;
			centroid[cur_sp + superpix_max] += j+1;
			// When we set BB left, it must be previously 0 since we scan from left to right
			if (bb[cur_sp] == 0)
				bb[cur_sp] = i+1;
			// This is top
			if (bb[cur_sp + superpix_max] == 0 || bb[cur_sp + superpix_max] > j+1)
				bb[cur_sp + superpix_max] = j+1;
			// Right
			if (bb[cur_sp + 2 * superpix_max] < i+1)
				bb[cur_sp + 2 * superpix_max] = i+1;
			// Bottom
			if (bb[cur_sp + 3 * superpix_max] < j+1)
				bb[cur_sp + 3 * superpix_max] = j+1;
			// Optional
			if (perimeter)
			{
				// Decide perimeter, if on the border, it's naturally perimeter
				if (i==0 || j==0 || i==width-1 || j==height -1)
					perimeter[cur_sp]++;
				// Unsatisfactory random access of memory here...
				else if (map[idx-1] != cur_sp +1 || map[idx+1] != cur_sp+1 || map[(i-1)*height + j] != cur_sp+1 || map[(i+1)*height + j] != cur_sp+1)
					perimeter[cur_sp]++;
			}
			if (second_moments)
			{
			// Second moments
				second_moments[cur_sp] += (i+1) * (i+1);
				second_moments[cur_sp + superpix_max] += (j+1) * (j+1);
				second_moments[cur_sp + 2 * superpix_max] += (i+1) * (j+1);
			}
			idx++;
		}
	}
	// Only centroid needs normalization
	for (i=0;i<superpix_max;i++)
		centroid[i] = centroid[i] / area[i];
	for (i=superpix_max;i<superpix_max * 2;i++)
		centroid[i] = centroid[i] / area[i-superpix_max];
}

void mexFunction(int nargout, mxArray *out[], int nargin, const mxArray *in[]) 
{

    /* declare variables */
    mwSize width, height;
    uint32_t *area, *perim = 0;
	mwSize channels;
	mwSize *sizes;
	uint16_t *sp_map, *bb;
	float *centroid, *secondorder = 0;
    
    /* check argument */
    if (nargin<1) {
        mexErrMsgTxt("One input argument required (superpixel_map )");
    }
    /* sizes */
    sp_map = (uint16_t *) mxGetData(in[0]);
    sizes = (mwSize *)mxGetDimensions(in[0]);
    height = sizes[0];
    width = sizes[1];

	// Currently
	uint16_t max_superpixels = sp_map[width * height - 1];
	for (unsigned i=0;i<width*height;i++)
	{
		if (max_superpixels < sp_map[i])
			max_superpixels = sp_map[i];
	}

	// This will initialize all values to 0
	out[0] = mxCreateNumericMatrix(max_superpixels,2, mxSINGLE_CLASS, mxREAL);
	out[1] = mxCreateNumericMatrix(max_superpixels,4, mxUINT16_CLASS, mxREAL);
	out[2] = mxCreateNumericMatrix(max_superpixels,1, mxUINT32_CLASS, mxREAL);
    if (out[0]==NULL || out[1]==NULL || out[2]==NULL) {
	    mexErrMsgTxt("Not enough memory for the output matrix");
    }
	centroid = (float *) mxGetData(out[0]);
	bb = (uint16_t *)mxGetData(out[1]);
	area = (uint32_t *) mxGetData(out[2]);
	if (nargout > 3)
	{
		out[3] = mxCreateNumericMatrix(max_superpixels,1, mxUINT32_CLASS, mxREAL);
		if (out[3] == NULL)
			mexErrMsgTxt("Not enough memory for the output matrix");
		perim = (uint32_t *) mxGetData(out[3]);
	}
	if (nargout > 4)
	{
		out[4] = mxCreateNumericMatrix(max_superpixels,3, mxSINGLE_CLASS, mxREAL);
		if (out[4] == NULL)
			mexErrMsgTxt("Not enough memory for the output matrix");
		secondorder = (float *) mxGetData(out[4]);
	}

	compute_regionprops(sp_map,height, width, max_superpixels, centroid, bb, area, perim, secondorder);
}
