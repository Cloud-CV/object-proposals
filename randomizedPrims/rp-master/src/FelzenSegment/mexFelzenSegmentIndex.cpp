#include <cmath>
#include "mex.h"
#include "segment-image.h"
#include "segment_image_index.h"
#include <time.h>
#include <string>
#include <fstream>

#define UInt8 char




void mexFunction(int nlhs, mxArray *out[], int nrhs, const mxArray *input[])
{

    
    // Checking number of arguments
    if(nlhs > 3){
        mexErrMsgTxt("Function has three return values");
        return;
    }

    if(nrhs != 4){
        mexErrMsgTxt("Usage: mexFelzenSegment(UINT8 im, double sigma, double c, int minSize)");
        return;
    }

    if(!mxIsClass(input[0], "uint8")){
        mexErrMsgTxt("Only image arrays of the UINT8 class are allowed.");
        return;
    }

    // Load in arrays and parameters
    UInt8* matIm = (UInt8*) mxGetPr(input[0]);
    int nrDims = (int) mxGetNumberOfDimensions(input[0]);
    int* dims = (int*) mxGetDimensions(input[0]);
    double* sigma = mxGetPr(input[1]);
    double* c = mxGetPr(input[2]);
    double* minSize = mxGetPr(input[3]);
    int min_size = (int) *minSize;

    int height = dims[0];
    int width = dims[1];
    int imSize = height * width;

    //SMANEN: Assertion
    int nChannels = dims[2];
    if(nChannels!=3){
        mexErrMsgTxt("Felzenszwalb segmentation should be called for images with 3 channels.");
        return;
    }

    int idx;
    image<rgb>* theIm = new image<rgb>(width, height);
    for (int x = 0; x < width; x++){
      for (int y = 0; y < height; y++){
        idx = x * height + y;
        imRef(theIm, x, y).r = matIm[idx];
        imRef(theIm, x, y).g = matIm[idx + imSize];
        imRef(theIm, x, y).b = matIm[idx + 2 * imSize];
      }
    }

    //SMANEN: Delete this
    /*mexPrintf("Warning: Saving passed image as a test. Delete/comment this afterwards.\n");
    srand(time(NULL));
    double r=rand();
    char filename[50];
    sprintf(filename,"seg_%f.dat",r);
    mexPrintf("Warning: Saving in file %s\n",filename);
    std::ofstream myfile;
    myfile.open (filename);
    for (int x = 0; x < width; x++){
      for (int y = 0; y < height; y++){

        idx = x * height + y;
        myfile<<(int)static_cast<unsigned char>(matIm[idx])<<"\n";
        myfile<<(int)static_cast<unsigned char>(matIm[idx + imSize])<<"\n";
        myfile<<(int)static_cast<unsigned char>(matIm[idx + 2 * imSize])<<"\n";
      }
    }

    myfile.close();*/


    // KOEN: Disable randomness of the algorithm
    //srand(12345);

    // Call Felzenswalb segmentation algorithm
    int num_css;
    //image<rgb>* segIm = segment_image(theIm, *sigma, *c, min_size, &num_css);
    double* segIndices = segment_image_index(theIm, *sigma, *c, min_size, &num_css);
    //mexPrintf("numCss: %d\n", num_css);

    // The segmentation index image
    out[0] = mxCreateDoubleMatrix(dims[0], dims[1], mxREAL);
    double* outSegInd = mxGetPr(out[0]);

    // Keep track of minimum and maximum of each blob
    out[1] = mxCreateDoubleMatrix(num_css, 4, mxREAL);
    double* minmax = mxGetPr(out[1]);
    for (int i=0; i < num_css; i++)
      minmax[i] = dims[0];
    for (int i= num_css; i < 2 * num_css; i++)
      minmax[i] = dims[1];

    // Keep track of neighbouring blobs using square matrix
    out[2] = mxCreateDoubleMatrix(num_css, num_css, mxREAL);
    double* nn = mxGetPr(out[2]);

    // Copy the contents of segIndices
    // Keep track of neighbours
    // Get minimum and maximum
    // These actually comprise of the bounding boxes
    double currDouble;
    int mprev, curr, prevHori, mcurr;
    for(int x = 0; x < width; x++){
      mprev = segIndices[x * height]-1;
      for(int y=0; y < height; y++){
        //mexPrintf("x: %d y: %d\n", x, y);
        idx = x * height + y;
        //mexPrintf("idx: %d\n", idx);
        //currDouble = segIndices[idx]; 
        //mexPrintf("currDouble: %d\n", currDouble);
        curr = segIndices[idx]; 
        //mexPrintf("curr: %d\n", curr);
        outSegInd[idx] = curr; // copy contents
        //mexPrintf("outSegInd: %f\n", outSegInd[idx]);
        mcurr = curr-1;

        // Get neighbours (vertical)
        //mexPrintf("idx: %d", curr * num_css + mprev);
        //mexPrintf(" %d\n", curr + num_css * mprev);
        //mexPrintf("mprev: %d\n", mprev);
        nn[(mcurr) * num_css + mprev] = 1;
        nn[(mcurr) + num_css * mprev] = 1;

        // Get horizontal neighbours
        //mexPrintf("Get horizontal neighbours\n");
        if (x > 0){
          prevHori = outSegInd[(x-1) * height + y] - 1;
          nn[mcurr * num_css + prevHori] = 1;
          nn[mcurr + num_css * prevHori] = 1;
        }

        // Keep track of min and maximum index of blobs
        //mexPrintf("Keep track of min and maximum index\n");
        if (minmax[mcurr] > y)
          minmax[mcurr] = y;
        if (minmax[mcurr + num_css] > x)
          minmax[mcurr + num_css] = x;
        if (minmax[mcurr + 2 * num_css] < y)
          minmax[mcurr + 2 * num_css] = y;
        if (minmax[mcurr + 3 * num_css] < x)
          minmax[mcurr + 3 * num_css] = x;

        //mexPrintf("Mprev = mcurr");
        mprev = mcurr;
      }
    }

    // Do minmax plus one for Matlab
    for (int i=0; i < 4 * num_css; i++)
      minmax[i] += 1;

    delete theIm;
    delete [] segIndices;

    mexPrintf("#########################################################\n");

    return;
}








