This package contains the Matlab implementations of the algorithms presented in the paper:

Generating object segmentation proposals using global and local search 
P. Rantalankila, J. Kannala, and E. Rahtu,
IEEE Conference on Computer Vision and Pattern Recognition, 2014 (CVPR 2014).


----------------------------------------------------------------------------------------

This software is distributed under the GNU General Public Licence (version 2 or later); 
please refer to the file Licence.txt, included with the software, for details.

The software is distributed in the hope that it will be useful, but 
WITHOUT ANY FURTHER SUPPORT and WITHOUT ANY WARRANTY; without even 
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

----------------------------------------------------------------------------------------

Contents:

spagglom.m - the main program
test_recalls.m and test_recalls_pixelwise.m - scripts to reproduce the experiments in the paper.


Additional software requirements:

1. VLFeat library, http://www.vlfeat.org (Version 9.16 was used in development) 

2. Graph-cut solver. See graphcut_regions.m for details. GCMex - MATLAB wrapper for graph cuts multi-label energy minimization http://vision.ucla.edu/~brian/gcmex.html was used in the development.

