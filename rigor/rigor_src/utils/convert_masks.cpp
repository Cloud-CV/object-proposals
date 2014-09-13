#include "mex.h"

// img_masks = convert_masks(sp_seg, masks)
// Convert superpixel segments into image segments
// sp_seg is the superpixel map
// masks is the superpixel segments
//
// @authors:     Fuxin Li
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014
        
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
	// read the parameters
	// check input
	int i,j,k;
	int idx_sp, idx;
	unsigned short *sp_seg;
	bool *masks;
	int nrows, ncols, nsegms, nsups;
	mwSize *dims = new mwSize[3];
	if( nrhs != 2 || mxGetClassID(prhs[0]) != mxUINT16_CLASS || mxGetClassID(prhs[1]) != mxLOGICAL_CLASS)
		mexErrMsgTxt("Usage: convert_masks(sp_seg, masks), sp_seg is the superpixel map (uint16) and masks are the superpixel segments.\n");
	
	nrows = mxGetM(prhs[0]);
	ncols = mxGetN(prhs[0]);
	nsegms = mxGetN(prhs[1]);
	nsups = mxGetM(prhs[1]);
	// convert the points to double
	dims[0] = nrows;
	dims[1] = ncols;
	dims[2] = nsegms;
	plhs[0] = mxCreateLogicalArray(3, dims);
	bool* segms = (bool *)mxGetData(plhs[0]);
	sp_seg = (unsigned short *) mxGetData(prhs[0]);
	masks = (bool *) mxGetData(prhs[1]);
	// Sequential access on the write and sp_seg
	idx = 0;
	for(k=0;k<nsegms;k++)
	{
		idx_sp = 0;
		for(i=0;i<nrows * ncols;i++)
		{
			short the_superpix = sp_seg[idx_sp];
			if(masks[the_superpix - 1 + k * nsups])
				segms[idx] = true;
			idx_sp++;
			idx++;
		}
	}
}
