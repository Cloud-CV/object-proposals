Objectness V2.2
===============

B. Alexe, T. Deselaers, V. Ferrari

This software was developed under Linux with Matlab R2010a.  There is no guarantee it will run on other operating systems or Matlab versions (though it probably will).
As a sub-component, this software uses the segmentation code of [3], which is included in this release.  We thank the authors of [3] for permission to redistribute their code as part of this release.


Introduction
------------

Welcome to this release of the objectness measure [1,2]. The objectness measure quantifies how likely it is for an image window to contain an object of any class.  This software computes the objectness measure (MS+CC+SS) defined in [1,2] and allows to sample any desired number of windows from an image according to their objectness probabilities. For applications, we recommend to sample about 1000 windows, which ensures covering most objects even in difficult images (e.g. with small objects and lots of clutter). However, in images of normal difficulty 100 windows are sufficient (e.g. images downloaded from image search engines).

In addition to the source code, we also release windows sampled from the objectness measure for every image from PASCAL VOC 2007 [4]. These ready-to-use windows should facilitate applications on this dataset.

From version V1.5 we include a new window sampling strategy (NMS) which leads to higher detection rates. On the highly challenging PASCAL VOC 2007 dataset [4], the top 1000 sampled windows now cover 91% of all objects [2], as opposed to about 70% in previous versions using multinomial sampling [1].

From release V2.0 we include a mex file that computes faster the segmentation [3]. In this version we also provide a function to compute the objectness heat map for an input image. In this heat map every pixel is assigned the average objectness score of all windows containing it. This is helpful to get a feeling for which image regions objectness reacts to, and for applications requiring pixel-level input, rather than window-level.

WARNING:
When using objectness in your application, it is important to take into account the score of a window returned by this software (i.e. their probability of covering an object). Depending on the image and on the sampling strategy used, it is well possible that some of the top 1000 windows are on the background, rather than on an object. However, their score is typically close to 0.


Quick start
-----------
Let <dir> be the directory where you uncompressed the release archive

cd <dir>
matlab
enter 'demo' in Matlab

demo.m does the following:
loads the image 002053.jpg
computes the objectness probability for all windows in this image
and then samples 10 windows according to their objectness (using NMS sampling). The demo then displays these 10 windows (brighter windows have higher objectness)

Sanity check:
if the figure that appears at step 4 of demo.m has several bright red windows on the train, then the code is working properly.


Setting things up
-----------------
The only mandatory operations are:
 1. add the code to the Matlab path (this is carried out in startup.m)
 2. load the default parameters and update the paths (this is carried out in startup.m)
 

Another optional operation (recommended):
 3. the variable dir_root in runObjectness.m is set to `pwd` to work
    directly as detailed in 'Quick start'. We recommend to move your
    data elsewhere and update dir_root accordingly. In this way the
    program will work regardless of the current working directory.


Sampling strategies
--------------------
From release V1.5 we include two strategies for sampling windows according to their objectness. The older "multinomial" strategy samples windows proportionally to their objectness. The new "nms" strategy samples windows in decreasing order of their objectness, so that no window overlaps substantially with a higher scored window (Pascal criterion: intersection-over-union < 0.5).

Each sampling strategy is suited to a different application. The "nms" sampling reaches a higher detection rate (91% on PASCAL VOC 2007 with 1000 windows), and we recommend it for most applications. On the other hand, the "multinomial" sampling offers more windows covering the same object. These multiple variants might be useful for applications needing highly accurate localization.

Of course, in any case you always get a score attached to each window, so you can always check how likely it is to cover an object or be on the background.
The default sampling strategy in the software is set to "nms". Changing the sampling strategy is easy: set params.sampling = "nms" or params.sampling = "multinomial".


Re-training objectness using your dataset
-----------------------------------------
In this release we include the objectness measure already trained from 50 images (see [1]) and ready to run on new images. The 50 training images were randomly sampled from several datasets, completely disjoint from PASCAL VOC 2007. These 50 training images are included in the release in [<dir> 'Training/Images/'].
We include here software for re-training the parameters of objectness using another training set. For this do:
1. put the training images in a different folder (called hereafter   'NewTrainingFolder')
2. build a struct analog to structGT from [<dir> '/Training/Images/'] and save it in NewTrainingFolder under the name 'structGT.mat'. This struct should have two fields: the name of the images (field 'img') in NewTrainingFolder and ground-truth bounding-boxes for each object in the image (field 'boxes').
3. run the function learnParameters using as a input the absolute path of 'NewTrainingFolder' (variable pathNewTrainingFolder). This function learns the parameters of the objectness measure using the images in the 'NewTrainingFolder' and saves the learned parameters in [<dir> '/Data/yourData/']. In order to run the software using the learned parameters set params.data = [<dir> '/Data/yourData/'].


Ready-to-use objectness windows for PASCAL VOC 2007
---------------------------------------------------
This release includes windows sampled from the objectness measure using both sampling strategies. 
We release sampled windows for every image in the PASCAL VOC 2007 dataset [4]. These are produced by the objectness measure trained from 50 images outside PASCAL VOC 2007 (see [1]).

For the "nms" sampling strategy we release up to 1000 windows per image (in some images there are fewer than 1000 windows that pass then non-maxima suppression procedure). For "multinomial" sampling we release 10000 windows per image.

This data is released in a second archive. Corresponding to each sampling strategy, the released data it is grouped in two subdirectories: VOCtest and VOCtrainval (as in [4]). For every image, there is one file containing (at most) 1000 lines (for "nms" sampling) or 10000 lines (for "multinomial" strategy). Every line stores a window represented as [xmin ymin xmax ymax prob], where 'prob' is the estimated probability that the window contains an object (i.e. its objectness score).

If you want to use only N windows from an image you can use the first N lines of these files. In the case of "nms", these will be the top scored N windows that pass the NMS procedure. In the case of "multinomial", these will be simply N windows sampled randomly from the objectness distribution. BEWARE: the windows in the "multinomial" files are *not* sorted by their objectness probability. This has a positive effect: keeping the top N lines preserves the objectness distribution. But if you want N high scored windows, then you will have to sort the lines by their objectness score first.



Matlab Functions
----------------

runObjectness
-------------
windows = runObjectness(img, numberSamples, params);
computes the objectness measure for a given image and samples from it.
Input:
    img - input image;
    numberSamples - number of samples (windows) to be drawn from the objectness distribution;
    params - parameters used to compute the objectness measure (they are loaded during the startup).
Output:
    windows(i,:) = [xmin ymin xmax ymax score]  set of the windows sampled.

learnParameters
---------------
params = learnParameters(pathNewTrainingFolder,dir_root);
learns the parameters of the objectness measure.
Input:
    pathNewTrainingFolder - absolute path of 'NewTrainingFolder';
    dir_root - path to the objectness code (see Setting things up).

computeObjectnessHeatMap
------------------------
objHeatMap = computeObjectnessHeatMap(img,windows)
computes the objectness heat map of an image. Every pixel is assigned the average objectness score of all windows containing it.
Input:
    img - input image;
    windows - objectness windows sampled from the objectness measure of the input image.


Support
-------
For any query/suggestion/complaint or simply to say you like/use this software, just drop us an email:

bogdan2win@gmail.com (please contact this address first)
vittoferrari@gmail.com

We wish you a good time using this software,
 Bogdan Alexe
 Thomas Deselaers
 Vittorio Ferrari


References
----------
[1] Bogdan Alexe, Thomas Deselaers and Vittorio Ferrari
    What is an object?,
    CVPR 2010, San Francisco, USA

[2] Bogdan Alexe, Thomas Deselaers and Vittorio Ferrari
    Measuring the objectness of image windows,
    PAMI, November 2012

[3] P. F. Felzenszwalb and D. P. Huttenlocher
    Efficient graph-based image segmentation,
    IJCV 2004
    http://people.cs.uchicago.edu/~pff/segment/

[4] M. Everingham, L. Van Gool, C. Williams, J. Winn, and A. Zisermann
    The PASCAL Visual Object Classes Challenge 2007.


Versions history
----------------
2.2
---
- minor speedups thanks to avoiding intermediate load/save steps; this software now no longer needs the external tool ‘convert’ to be installed on your machine

2.1
---
- bug fixed: sampling windows for small sized images doesn't crash anymore

2.0
---
- mex file to compute the segmentation [3] faster
- function to compute the objectness heat map of an image added

1.5
---
- NMS sampling procedure added

1.01
----
- bug fixed: windows with width or height = 1 are not anymore considered

1.0
---
- first public release
- included ready-to-use windows for PASCAL VOC 2007

0.9
---
- First semi-internal release for testers
