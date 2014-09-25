/* Copyright (C) 2010 Joao Carreira

 This code is part of the extended implementation of the paper:
 
 J. Carreira, C. Sminchisescu, Constrained Parametric Min-Cuts for Automatic Object Segmentation, IEEE CVPR 2010
 */

/*---
function [o] = overlap_over_threshold(segms, thres, sp_areas)
Input:
    segms - binary matrix, with segms in columns  
	thres - scalar determining the threshold
	sp_areas - the area of each superpixel
Output:
    o = symmetric overlap matrix
--*/

#include "mex.h"
#include "math.h"
#include "time.h"
#include "stdint.h"
#include "omp.h"

//extern void overlap(unsigned int *intersections, unsigned int *reunions, mxLogical *segms, int nc, int nr);
//extern void overlap_sp(unsigned int *intersections, unsigned int *reunions, mxLogical *segms, unsigned int *sp_seg_sz, int nc, int nr);
// segm1 and segm2 are vectors representing the nonzeros of the 2 segments
float match_two_segments(const unsigned int *segm1, const unsigned int *segm2, const int &area1, const int &area2, int max_bad)
{
	unsigned int res_int, res_uni;
	int counter1, counter2;
	res_int = res_uni = 0;
	counter1 = counter2 = 0;
	while(counter1 < area1 && counter2 < area2)
	{
		if(segm1[counter1] == segm2[counter2])
		{
			res_int++;
			res_uni++;
			counter1++;
			counter2++;
		}
		else
		{
			// always+1 because now we are counting away from the one we deemed not matching
			res_uni++;
			if(segm1[counter1] > segm2[counter2])
				counter2++;
			else
				counter1++;
			if(res_uni - res_int > max_bad)
				return 0.0;
		}
	}
	// Add all those that have not been looped
	res_uni += area1 - counter1 + area2 - counter2;
	return (float)(res_int) / res_uni;
}

void compute_area(const bool *segms, int nsegms, int npixels, int *area)
{
	int i,j;
        uint64_t idx = 0;
	for (i=0;i<nsegms;i++)
		for (j=0;j<npixels;j++, idx++)
		{
			if(segms[idx])
				area[i]++;
		}
}


void overlap_thr(float *overlaps, unsigned int **new_segms, int nc, int nr, const int *area, double thres) {
#pragma omp parallel for schedule(dynamic, 2)
    for(int i=0; i<nc; ++i) { /* for each segment */
        int j, index_ij, index_ik, index_jk, k, res_int, res_uni;
        index_ij = i * (nc +1)+1;
        for(j=i+1; j<nc; ++j) { /* go through the others with j>i */
			double area_both = area[i] + area[j];
			int max_bad = floor((1 - thres) * area_both);
			overlaps[i * nc + j] = match_two_segments(new_segms[i], new_segms[j], area[i], area[j],max_bad);
			overlaps[j * nc + i] = overlaps[i * nc + j];
        }
	}
    return;
}


void mexFunction(
    int nargout,
    mxArray *out[],
    int nargin,
    const mxArray *in[]) {

    /* declare variables */
    int npixels, nsegms;
    register unsigned int index_ij, index_ik, index_jk;
    int i, j, k;
    mxLogical *segms;
    unsigned int *sp_seg_szs;
	double thres;
    float *o;
    
    /* check argument */
    if (nargin<2) {
        mexErrMsgTxt("Two input argument required ( the segments in column form, desired threshold )");
    }
    if (nargout>1) {
        mexErrMsgTxt("Too many output arguments");
    }

    npixels = mxGetM(in[0]);
    nsegms = mxGetN(in[0]);

    if (!mxIsLogical(in[0]) || mxGetNumberOfDimensions(in[0]) != 2) {
        mexErrMsgTxt("Usage: segms must be a logical matrix");
    }
    
    segms = (bool *) mxGetData(in[0]);
	thres = mxGetScalar(in[1]);
    
    /* if the user provided the SP areas */
    if (nargin == 3) { 
        if (!mxIsUint32(in[1]) || mxGetNumberOfElements(in[1]) != npixels) {
            mexErrMsgTxt("Usage: the second (optional) argument should give the weight/area of each superpixel in uint32 and the number of elements should be same # of rows as first argument.");
        }
        sp_seg_szs = (unsigned int*) mxGetData(in[1]);
    }
    
    out[0] = mxCreateNumericMatrix(nsegms,nsegms,mxSINGLE_CLASS, mxREAL);
    if (out[0]==NULL) {
	    mexErrMsgTxt("Not enough memory for the output matrix");
    }
    o = (float *) mxGetData(out[0]);

  	/*clock_t begin=clock();*/
    /* intersections and reunions */
	int *area = new int[nsegms]();
	compute_area(segms, nsegms, npixels,area);
	unsigned int **new_segms = new unsigned int *[nsegms];
// Convert all the segments to sparse format to facilitate quicker comparisons
	for (i=0;i<nsegms;i++)
	{
		new_segms[i] = new unsigned int [area[i]];
	}
	
#pragma omp parallel for schedule (dynamic,2) private(i,j)
	for (i=0;i<nsegms;i++)
	{
		unsigned int counter = 0;
		uint64_t idx = npixels * i;
		for(j=0;j<npixels;j++, idx++)
		{
			if (segms[idx])
				new_segms[i][counter] = j, counter++;
		}
	}
        overlap_thr(o, new_segms, nsegms, npixels, area, thres);
    /* fill diagonal with ones */
    for (i=0; i<nsegms; i++) {
       o[i*nsegms+i] = 1;
    }
	for (i=0;i<nsegms;i++)
	{
		delete []new_segms[i];
		new_segms[i] = 0;
	}
	delete []new_segms;
        new_segms = 0;
        delete []area;
        area = 0;
}
