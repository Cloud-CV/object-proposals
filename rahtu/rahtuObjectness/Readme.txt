This program package implements the method described in 

Rahtu E. & Kannala J. & Blaschko M. B. 
Learning a Category Independent Object Detection Cascade. 
Proc. International Conference on Computer Vision (ICCV 2011).

The algorithm needs the executables of Pedro F. Felzenszwalb's and Daniel P. Huttenlocher's superpixel segmentation algorithm. You can download the code from:
http://www.cs.brown.edu/~pff/segment/

The code includes the SS feature developed and described by
Alexe B., Deselaers T. & Ferrari V. (2010) What is an object? Proc The IEEE Conference on Computer Vision and Pattern Recognition (CVPR).

As the code is dependent on these two implementations, the speed of the method is dependent on their efficiency in addition to the computation time of the features described in our ICCV paper.

Setting up:

1. Download and compile Pedro F. Felzenszwalb's superpixels segmentation program.

2. Modify the mvg_FelzenswalbSuperpixelWrapper.m file by updating the path to Felzenszwalb's superpixel executables.

3. Run compileObjectnessMex.m to compile the mex files in this package. 


Usage:

The main file is mvg_runObjectDetection.m See the help text for more usage details and examples.


If you use results derived from this code in your publications, please cite the following papers:
* Rahtu E. & Kannala J. & Blaschko M. B. (2011) Learning a Category Independent Object Detection Cascade. Proc. International Conference on Computer Vision (ICCV 2011).
* Alexe B., Deselaers T. & Ferrari V. (2010) What is an object? Proc The IEEE Conference on Computer Vision and Pattern Recognition (CVPR).
* Pedro F. Felzenszwalb and Daniel P. Huttenlocher, Efficient Graph-Based Image Segmentation, International Journal of Computer Vision, Volume 59, Number 2, September 2004
