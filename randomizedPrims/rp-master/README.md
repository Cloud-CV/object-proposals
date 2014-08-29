Prime Object Proposals with Randomized Prim's Algorithm (RP)

===========================================================

S. Manen, M. Guillaumin, L. Van Gool
{smanenfr, guillaumin, vangool}@vision.ee.ethz.ch

This software was developed under Linux with Matlab R2013a.  There is no guarantee it will run on other operating systems or Matlab versions (though it probably will).
As a sub-component, this software uses the segmentation code of [2], which is included in this release.  We thank the authors of [2] for permission to redistribute their code as part of this release.

Introduction
------------

Welcome to the release of the Randomized Prim's algorithm (RP) for Object Proposals[1]. RP can be used to propose a set of windows that have a high probability of containing and properly fitting the objects of an image, regardless of their class. To this end, it first segments the image in superpixels and then it grows groups of superpixels according to the probability that they belong to the same object. This set of windows can be used for further processes, such as object detection and weakly supervised learning. The code is efficient, usually taking less than 0.5s to process an image.

NOTE: The current version of the code runs one additional LAB conversion for each segmentation from which proposals are sampled. This makes it slightly slower than the version reported in the paper.

Quickstart
----------

An interactive demo application for the method can be easily executed with the following steps:

  1. Open a Matlab console.
  2. Execute the script setup.m
  3. Run demo.m for an interactive demo.

The demo proposes windows for a set of images and allows the user to interactively explore the set of windows to get a feeling of the quality of the proposals. To do so, the demo shows that proposal whose center is the closest to the cursor of the user. That is, to see if the object hs been found the user should try to position the mouse close to the center of the "bounding box" of the object.

Frequently Asked Questions (FAQ):
---------------------------------

- How can I get more proposals? 

  The method has not been designed to get a specific number of proposals. Given the nature of the algorithm, the number of proposals can be increased by using more superpixels (i.e. lowering .superpixels.min_size in the config file) or by using more segmentations (config/GenerateRPConfig_4segs.m uses 4 segmentations but more can be included).

- How can I evaluate the method on VOC 2007?

  An evaluation script is included in the release to reproduce the results of the paper. You can configure the paths in the script 'evaluation/evalVOC2007.m' and execute it to obtain the VUS and the curve corresponding to Fig6c in the paper. You will need to download the test set of VOC2007 and include the path in 'evaluation/evalVOC2007.m'. Note that there is a part in evaluation/ComputeProposals.m that can be parallelized to speed up the evaluation.

  Some details that are included in the evaluation are:

    a. As aforementioned, the method will return a number N of proposals depending on the number of superpixels. If the evaluation is up to M proposals and M>N, then only the N returned proposals are used for the evaluation. 

    b. Our method independently generates proposals, some of which might be repeated, and near-duplicates are removed. The number of independently generated proposals is proportional to approxNProposals, which is 100,000 in our experiments. Naturally, the more approxNProposals that we generate, the slower the method becomes. 

Main Functions
--------------

The demo is only intended for visualization purposes. To generate object proposals for a specific application, however, one should use the RP matlab function. Use this function to simply take an RGB image and return object proposals as bounding boxes, according to some parameters. Read below how the parameters can be changed.

Configuration and parameters
----------------------------

There are certain parameters that define the behaviour of RP. The set of parameters used in the paper can be found in config/GenerateRPConfig.m and config/GenerateRPConfig_4segs.m. The former refers to the version of RP that only samples groups of superpixels from a segmentation in the LAB colorspace, whereas the latter samples from the LAB, HSV, rg and opponent colorspaces. The overhead for sampling from more colorspaces is higher, due to the time needed to compute the colorspace conversions and the superpixel segmentations. A more detailed comparison can be found in the paper. Also notice that both configuration files include the parameters trained with the VOC07 dataset. These scripts are automatically called by setup.m to generate the configuration files (.mat). Read the simple code of InteractiveCenterDemo.m to see how a configuration file is read and how RP is called.

Quickstart to propose objects for specific applications
----------------------------------------------------------

We recommend the following steps to use RP for new applications:

  1. Start by deciding which configuration file you want to use, or if you want to make one of your own. ]
     In case of doubt, we recommend using config/GenerateRPConfig_4segs.m due to its accuracy. Remember that config/GenerateRPConfig.m is faster, but at the cost of a drop in accuracy.

  2. Load the configuration file with LoadConfigFile.

  3. Finally simply call RP.m providing the RGB image and with the loaded parameters. The function returns the list of bounding boxes.

An example set of instructions for this would be:
  setup
  addpath('matlab');
  addpath('mex');
  img = imread('test_images/000013.jpg');
  config = LoadConfigFile('config/rp.mat');
  proposals = RP(img, config)

NOTE: If you just want to test RP for a specific image i.e. before you consider using it more seriously, you can just copy your test image to test_images.jpg. Then it will be added to the pool of images on which RP is run in the demo. It is even possible to delete the rest of the images so that you do not have to cycle through them in the demo.

References
----------
    
[1] S. Manen, M. Guillaumin, and L. Van Gool. 
    Prime Object Proposals with Randomized Prim's Algorithm. 
    In ICCV, 2013.

[2] P. F. Felzenszwalb and D. P. Huttenlocher
    Efficient graph-based image segmentation.
    In IJCV, 2004
    http://people.cs.uchicago.edu/~pff/segment/

