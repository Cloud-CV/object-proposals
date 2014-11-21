Object-proposals:
================

This is a library/API which can be used to generate bounding box/region proposals using a large number of the existing object proposal approaches.

It is fully supported on Linux and partially supported on macOS. Rigor, Randomized prim are NOT supported on macOS.
Rigor requires installation of boost, tbb libraries.

Compile:
========
i. Run compile.m



 Generating proposals:
======

i. Initialize path variables using:
> initialize;

ii. To generate proposals, you can use either of the following commands:
> proposals = runObjectProposals('< proposalname >', 'path\to\image.jpg');

 or
> im=imread('path\to\image.jpg'); proposals = runObjectProposals('< proposal name >', im);


iii. For long-running jobs, open config.json; Set *imageLocation*, and *outputLocation* to locations of your choice.

Once  *imageLocation*, and *outputLocation* are set, you can call
>runObjectProposals('< proposal name >');

This will generate proposals for all the images in the *imageLocation* and save the proposals in the *outputLocation*.

In steps (ii) and (iii) < proposalname > is the object proposal you want to run.  Here are the possible names that can be passed to the function are:
  * edgeBoxes  [1]
  * endres  [2]
  * mcg  [3]
  * objectness  [4]
  * rahtu  [5]
  * randomPrim [6]
  * rantalankila  [7]
  * selective_search [8]
  * rigor [9]

Note:
        RIGOR requires boost and tbb libraries. Please follow the instruction at https://docs.google.com/document/d/19hEkfpPsRYnYHBBmWxI-EMFPkkO-fhhDx8Js4HFrKv8 to setup these libraries.
        RIGOR does not support .mat as argument for calcrigorForIm function. It only accepts the image path.

Evaluating proposals:
=====================
 
A ground truth file needs to be generated for the dataset. We have provided the file for PASCAL 2007 test set. The following code assumes you have generated proposals for all the images in the dataset for which you want to evaluate for each proposal in your config.json file. 
### Evaluation using recall curves and area under recall curves
i. load groundtruth.
> testset=load('evaluation-metrics/data/pascal_gt_data.mat');

ii. generate best recall candidates
> compute_best_recall_candidates(testset,configjson);

iii. plot RECALL/AUC curves.
> evaluateMetricForProposal('RECALL','< proposalName>');
> evaluateMetricForProposal('AUC','< proposalName');

or

> evaluateMetricForProposal('RECALL');   
> evaluateMetricForProposal('AUC');

### Evaluation using ABO curves

i. load groundtruth.
>testset=load('evaluation-metrics/data/pascal_gt_data.mat');

ii. generate best recall candidates
> compute_abo_candidates(testset,configjson);

iii. plot ABO curve
> evaluateMetricForProposal('ABO', '< proposalName');

or 
> evaluateMetricForProposal('ABO');



License:
==================
The original license for each object proposal has been retained in their respective folders. Please refer to individual license before using the specific object proposal.


Citations
==================
This package contain various object proposal implementations of the algorithms presented in the following papers. If you are using object proposals presented in these papers, we request you to cite appropriate papers:

[1] EdgeBoxes:



    @inproceedings{ZitnickECCV14,
        Author = {C. Lawrence Zitnick and Piotr Dollar},
        Title = {Edge Boxes: Locating Object Proposals from Edges},
        Booktitle = {ECCV},
        Year = {2014},
    }
 Licence: edgeBoxes/releaseV3/license.txt (MICROSOFT RESEARCH LICENSE TERMS)

[2] Endres - Category Independent Object Proposals:




    @article{EndresPAMI14,
        Author = {Ian Endres and Derek Hoiem},
        Title = {Category-Independent Object Proposals with Diverse Ranking},
        Journal ={IEEE Transactions on Pattern Analysis and Machine Intelligence},
        volume = {36},
        number = {2},
        issn = {0162-8828},
        year = {2014},
        pages = {222-234},
    }
License: endres/proposals/README( GNU General Public License)

[3] MCG: Multiscale Combinatorial Grouping:




    @inproceedings{Arbelaez_CVPR14,
        Author = {Arbel\'{a}ez, P. and Pont-Tuset, J. and Barron, J. and Marques,F. and Malik, J.},
        Title = {Multiscale Combinatorial Grouping},
        Booktitle = {CVPR},
        year = {2014}
    }
License: mcg/MCG-Full/license.txt (BSD)

[4] Objectness:



    @article{AlexePAMI12,
        Author = {Alexe, Bogdan and Deselaers, Thomas and Ferrari, Vittorio},
        Title = {Measuring the objectness of image windows },
        Journal ={IEEE Transactions on Pattern Analysis and Machine Intelligence},
        year = {2012},
    }
License: objectness-release-v2.2/LICENSE.txt (rights to use, copy, modify, merge and distribute)

[5] Rahtu:



    @inproceedings{RahtuICCV11,
        author    = {Esa Rahtu and Juho Kannala and Matthew B. Blaschko},
        title     = {Learning a category independent object detection cascade},
        booktitle = {ICCV},
        year      = {2011},
    }
License: rahtu/rahtuObjectness/Licence.txt( MIT licence)

[6] Randomized Prims:


    @inproceedings{ManenICCV13,
         author = {Manen, Santiago and Guillaumin, Matthieu and Gool, Luc Van},
         title = {Prime Object Proposals with Randomized Prim's Algorithm},
         booktitle = {ICCV},
        year = {2013},
    }
License: randomizedPrims/rp-master/LICENSE.txt(same as [4])

[7] Rantalankila:

    @inproceedings{RantalankilaCVPR14,
        author = {Rantalankila, Pekka and Kannala, Juho and Rahtu, Esa},
        title = {Generating Object Segmentation Proposals using Global and Local Search},
        booktitle = {CVPR},
        year = {2014}
    }
License: rantalankilaSegments/Readme.txt (GNU General Public Licence)

[8] Selective Search:


    @article{UijlingsIJCV13,
        author = {J.R.R. Uijlings and K.E.A. van de Sande and T. Gevers and A.W.M. Smeulders},
        title = {Selective Search for Object Recognition},
        journal = {International Journal of Computer Vision},
        year = {2013},
        url = {http://www.huppelen.nl/publications/selectiveSearchDraft.pdf}
    }
License: selective_search/License.txt(Copyright University of Amsterdam)

[9] rigor:

        @inproceedings{HumayunCVPR14,
             author    = {Ahmad Humayun and Fuxin Li and James M. Rehg},
             title = {RIGOR- Recycling Inference in Graph Cuts for generating Object Regions},
             booktitle = {CVPR},
             year = {2014}
            }
License: rigor/rigor_src/LICENSE ( GNU General Public License)


[10] Evaluation Metrics:

    @inproceedings{HosangBMVC14,
        author = {J. Hosang and R. Benenson and B. Schiele},
        title = {How good are detection proposals, really?},
        booktitle = {BMVC},
        year = {2014}
    }
License: evaluation-metrics/LICENSE(GNU GENERAL PUBLIC LICENSE)
