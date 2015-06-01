Object Proposals
================

This is a library/API which can be used to generate bounding box/region proposals using a large number of the existing object proposal approaches. If you use use our library, please cite our paper:

@misc{1505.05836,
Author = {Neelima Chavali and Harsh Agrawal and Aroma Mahendru and Dhruv Batra},
Title = {Object-Proposal Evaluation Protocol is 'Gameable'},
Year = {2015},
Eprint = {arXiv:1505.05836},
}

* It is fully supported on Linux and partially supported on Mac OS.
* Rigor, Randomized Prim are NOT supported on Mac OS.
* Rigor requires installation of [boost][boost], [tbb][tbb] libraries.
* Geodesic Object Proposals require c++11 compiler (C++ 4.7 or higher) and [eigen][eigen] (3.2 or higher).

Compiling
---------

1. Run `compile.m`


Generating Proposals
--------------------

1. Copy over `config.json.example` to `config.json` and set `imageLocation` and `outputLocation`.

2. Initialize path variables.
```
initialize;
```

3. Generate proposals, using either of the following commands.
```
proposals = runObjectProposals('<proposalname>', 'path\to\image.jpg');

OR 

im = imread('path\to\image.jpg');
proposals = runObjectProposals('<proposal name>', im);
```

4. For long-running jobs, use the following command.
```
runObjectProposals('<proposalname>');
```
This will generate proposals for all the images in `imageLocation` and save the proposals in `outputLocation`.

`<proposalname>` is the object proposal to be run. List of possible object proposal names:

* `edgeBoxes` [1]
* `endres` [2]
* `mcg` [3]
* `objectness` [4]
* `rahtu` [5]
* `randomPrim` [6]
* `rantalankila` [7]
* `selective_search` [8]
* `rigor` [9]
* `gop` [10]
* `lpo` [11]

**Note**

RIGOR requires [boost][boost] and [tbb][tbb] libraries. Please follow the instructions given [here](https://docs.google.com/document/d/19hEkfpPsRYnYHBBmWxI-EMFPkkO-fhhDx8Js4HFrKv8) to setup these libraries.

Evaluating Proposals
--------------------
 
A ground truth file needs to be generated for the dataset. We have provided the file for PASCAL 2007 test set. The following code assumes you have generated proposals for all images in the dataset for which you want to evaluate for each proposal in your `config.json` file.

### Evaluation using recall curves & area under recall curves

1. Load ground truth.
```
testset=load('evaluation-metrics/data/pascal_gt_data.mat');
```

2. Generate best recall candidates.
```
compute_best_recall_candidates(testset,configjson,'<proposalame>'); 
```
'proposalname' is an optional argument. If not provided, the function works for all the object proposals listed above.

3. Plot RECALL/AUC curves.
```
evaluateMetricForProposal('RECALL','<proposalname>');
evaluateMetricForProposal('AUC','<proposalname');

OR

evaluateMetricForProposal('RECALL');   
evaluateMetricForProposal('AUC');
```

### Evaluation using ABO curves

1. Load ground truth.
```
testset=load('evaluation-metrics/data/pascal_gt_data.mat');
```

2. Generate best recall candidates.
```
compute_abo_candidates(testset,configjson);
```

3. Plot ABO curve.
```
evaluateMetricForProposal('ABO', '<proposalname');

OR

evaluateMetricForProposal('ABO');
```

Possible Issues
---------------

### Linux

* While running `runObjectProposals('mcg')`, you may get an error like  
```Invalid MEX-file 'path/to/ucm_mean_pb.mexa64': /matlab/path/to/libstdc++.so.6: version GLIBCXX_3.4.15' not found.``` This issue is explained [here](http://www.mlpack.org/trac/ticket/253). Possible workaround is to start MATLAB with `"LD_PRELOAD=/path/to/libstdc++.so.6 matlab"`. Replace `/path/to/libstdc++.so.6` with the system install location for libstdc++, usually something like `/usr/lib/x86_64-linux-gnu/libstdc++.so.6`. 

License
-------
The original license for each object proposal has been retained in their respective folders. Please refer to individual license before using the specific object proposal.


Citations
---------
This package contains various object proposal implementations of the algorithms presented in the following papers. If you are using object proposals presented in these papers, we request you to cite appropriate papers:

[1] EdgeBoxes:

    @inproceedings{ZitnickECCV14,
        Author = {C. Lawrence Zitnick and Piotr Dollar},
        Title = {Edge Boxes: Locating Object Proposals from Edges},
        Booktitle = {ECCV},
        Year = {2014},
    }
 
 License: [edgeBoxes/releaseV3/license.txt](edgeBoxes/releaseV3/license.txt) (MICROSOFT RESEARCH LICENSE TERMS)

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

License: [endres/proposals/README](endres/proposals/README) (GNU General Public License)

[3] MCG - Multiscale Combinatorial Grouping:

    @inproceedings{Arbelaez_CVPR14,
        Author = {Arbel\'{a}ez, P. and Pont-Tuset, J. and Barron, J. and Marques,F. and Malik, J.},
        Title = {Multiscale Combinatorial Grouping},
        Booktitle = {CVPR},
        year = {2014}
    }

License: [mcg/MCG-Full/license.txt](mcg/MCG-Full/License.txt) (BSD)

[4] Objectness:

    @article{AlexePAMI12,
        Author = {Alexe, Bogdan and Deselaers, Thomas and Ferrari, Vittorio},
        Title = {Measuring the objectness of image windows },
        Journal ={IEEE Transactions on Pattern Analysis and Machine Intelligence},
        year = {2012},
    }

License: [objectness-release-v2.2/LICENSE.txt](objectness-release-v2.2/LICENSE.txt) (rights to use, copy, modify, merge and distribute)

[5] Rahtu:

    @inproceedings{RahtuICCV11,
        author    = {Esa Rahtu and Juho Kannala and Matthew B. Blaschko},
        title     = {Learning a category independent object detection cascade},
        booktitle = {ICCV},
        year      = {2011},
    }

License: [rahtu/rahtuObjectness/Licence.txt](rahtu/rahtuObjectness/Licence.txt) (MIT license)

[6] Randomized Prims:

    @inproceedings{ManenICCV13,
         author = {Manen, Santiago and Guillaumin, Matthieu and Gool, Luc Van},
         title = {Prime Object Proposals with Randomized Prim's Algorithm},
         booktitle = {ICCV},
        year = {2013},
    }

License: [randomizedPrims/rp-master/LICENSE.txt](randomizedPrims/rp-master/LICENSE.txt) (rights to use, copy, modify, merge and distribute)

[7] Rantalankila:

    @inproceedings{RantalankilaCVPR14,
        author = {Rantalankila, Pekka and Kannala, Juho and Rahtu, Esa},
        title = {Generating Object Segmentation Proposals using Global and Local Search},
        booktitle = {CVPR},
        year = {2014}
    }

License: [rantalankilaSegments/Readme.txt](rantalankilaSegments/Readme.txt) (GNU General Public License)

[8] Selective Search:

    @article{UijlingsIJCV13,
        author = {J.R.R. Uijlings and K.E.A. van de Sande and T. Gevers and A.W.M. Smeulders},
        title = {Selective Search for Object Recognition},
        journal = {International Journal of Computer Vision},
        year = {2013},
        url = {http://www.huppelen.nl/publications/selectiveSearchDraft.pdf}
    }

License: [selective_search/License.txt](selective_search/License.txt) (Copyright University of Amsterdam)

[9] rigor:

    @inproceedings{HumayunCVPR14,
         author    = {Ahmad Humayun and Fuxin Li and James M. Rehg},
         title = {RIGOR- Recycling Inference in Graph Cuts for generating Object Regions},
         booktitle = {CVPR},
         year = {2014}
        }

License: [rigor/rigor_src/LICENSE](rigor/rigor_src/LICENSE) (GNU General Public License)

[10] Geodesic Object Proposals:

    @inproceedings{DBLP:conf/eccv/KrahenbuhlK14,
      author    = {Philipp Kr{\"{a}}henb{\"{u}}hl and
                   Vladlen Koltun},
      title     = {Geodesic Object Proposals},
      booktitle = {Computer Vision - {ECCV} 2014 - 13th European Conference, Zurich,
                   Switzerland, September 6-12, 2014, Proceedings, Part {V}},
      pages     = {725--739},
      year      = {2014}
    }

License: BSD

[11] Learning to Propose Objects:

    @inproceedings{kk-lpo-15,
      author    = {Philipp Kr{\"{a}}henb{\"{u}}hl and
                   Vladlen Koltun},
      title     = {Learning to Propose Objects},
      booktitle = {CVPR},
      year      = {2015},
    }

License: BSD

[12] Evaluation Metrics:

    @inproceedings{HosangBMVC14,
        author = {J. Hosang and R. Benenson and B. Schiele},
        title = {How good are detection proposals, really?},
        booktitle = {BMVC},
        year = {2014}
    }

License: [evaluation-metrics/LICENSE](evaluation-metrics/LICENSE) (GNU General Public License)

[boost]: http://www.boost.org/
[tbb]: https://www.threadingbuildingblocks.org/
[eigen]: http://eigen.tuxfamily.org/index.php?title=Main_Page
