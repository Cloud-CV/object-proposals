Object-proposals:
================

This is a library/API which can be used to generate bounding box/region proposals using most of the existing object proposal approaches.


Usage:
======

i. Open config.json. Set *imageLocation*, and *outputLocation* to locations of your choice. (All other config values have been set to default values)

ii. First time users:

> compile;

> proposals = runObjectProposals('<proposalname>', 'path\to\image.jpg');
 
 or
> im=imread('path\to\image.jpg'); proposals = runObjectProposals('<proposal name>', im);


If you have already compiled once, use the initialize command instead of compile commande before generating proposals.

iii. Alternately, you can call
>runObjectProposals('<proposal name>');

This will generate proposals for all the images in the *imageLocation* and save the proposals in the *outputLocation*.
 
In steps (ii) and (iii) < proposalname> is the object proposal you want to run.  Here are the possible names that can be passed to the function are:
  * edgeBoxes  [1]
  * endres  [2]
  * mcg  [3]
  * objectness  [4]
  * rahtu  [5]
  * randomPrim [6]
  * rantalankila  [7]
  * selective_search [8]

License:
==================
The original license for each object proposal has been retained in their respective folders. Please refer to individual license before using the specific object proposal.


Citations
==================
This package contain various object proposal implementations of the algorithms presented in the following papers. If you are using object proposals presented in these papers, we request you to cite appropriate papers:

[1] EdgeBoxes: 
    


    @inproceedings{ZitnickECCV14edgeBoxes,
        Author = {C. Lawrence Zitnick and Piotr Dollar},
        Title = {Edge Boxes: Locating Object Proposals from Edges},
        Booktitle = {ECCV},
        Year = {2014},
    }
 Licence: edgeBoxes/releaseV3/license.txt (MICROSOFT RESEARCH LICENSE TERMS)
 
[2] Endres - Category Independent Object Proposals:




    @article{10.1109/TPAMI.2013.122,
        Author = {Ian Endres and Derek Hoiem},
        Title = {Category-Independent Object Proposals with Diverse Ranking},
        Journal ={IEEE Transactions on Pattern Analysis and Machine Intelligence},
        volume = {36},
        number = {2},
        issn = {0162-8828},
        year = {2014},
        pages = {222-234},
        doi = {http://doi.ieeecomputersociety.org/10.1109/TPAMI.2013.122},
        publisher = {IEEE Computer Society},
        address = {Los Alamitos, CA, USA},
    } 
License: endres/proposals/README( GNU General Public License)

[3] MCG: Multiscale Combinatorial Grouping:

    
    
    
    @inproceedings{APBMM2014,
        Author = {Arbel\'{a}ez, P. and Pont-Tuset, J. and Barron, J. and Marques,F. and Malik, J.},
        Title = {Multiscale Combinatorial Grouping},
        Booktitle = {Computer Vision and Pattern Recognition},
        year = {2014}
    } 
License: mcg/MCG-Full/license.txt (BSD)

[4] Objectness:



    @string{pami="IEEE Transactions on Pattern Analysis and Machine Intelligence     (TPAMI)"}
    @string{calvinroot="http://groups.inf.ed.ac.uk/calvin/"}
    @Article{Alexe2012pami,
        Author = {Alexe, Bogdan and Deselaers, Thomas and Ferrari, Vittorio},
        Title = {Measuring the objectness of image windows },
        journal = pami,
        year = 2012,
        url = calvinroot # {objectness/},
        pdf = calvinroot # {Publications/alexe12pami.pdf},
    } 
License: objectness-release-v2.2/LICENSE.txt (rights to use, copy, modify, merge and distribute)

[5] Rahtu:



    @inproceedings{DBLP:conf/iccv/RahtuKB11,
        author    = {
               Esa Rahtu and
               Juho Kannala and
               Matthew B. Blaschko},
        title     = {
                Learning a category independent object detection cascade
                },
         booktitle = {{IEEE} International Conference on Computer Vision, {ICCV} 2011, Barcelona,
               Spain, November 6-13, 2011},
        year      = {2011},
        pages     = {1052--1059},
        crossref  = {DBLP:conf/iccv/2011},
        url       = {http://dx.doi.org/10.1109/ICCV.2011.6126351},
        doi       = {10.1109/ICCV.2011.6126351},
        timestamp = {Fri, 19 Sep 2014 06:11:46 +0200},
        biburl    = {http://dblp.uni-trier.de/rec/bib/conf/iccv/RahtuKB11},
        bibsource = {dblp computer science bibliography, http://dblp.org}
    }
License: rahtu/rahtuObjectness/Licence.txt( MIT licence)

[6] Randomized Prims:


    @inproceedings{Manen:2013:POP:2586117.2587333,
         author = {Manen, Santiago and Guillaumin, Matthieu and Gool, Luc Van},
         title = {Prime Object Proposals with Randomized Prim's Algorithm},
         booktitle = {Proceedings of the 2013 IEEE International Conference on Computer Vision},
        series = {ICCV '13},
        year = {2013},
        isbn = {978-1-4799-2840-8},
        pages = {2536--2543},
        numpages = {8},
        url = {http://dx.doi.org/10.1109/ICCV.2013.315},
        doi = {10.1109/ICCV.2013.315},
        acmid = {2587333},
        publisher = {IEEE Computer Society},
        address = {Washington, DC, USA},
        keywords = {Object Detection, Object Proposal},
    }
License: randomizedPrims/rp-master/LICENSE.txt(same as [4])

[7] Rantalankila:

    @InProceedings{Rantalankila_2014_CVPR,
        author = {Rantalankila, Pekka and Kannala, Juho and Rahtu, Esa},
        title = {Generating Object Segmentation Proposals using Global and Local Search},
        journal = {The IEEE Conference on Computer Vision and Pattern Recognition (CVPR)},
        month = {June},
        year = {2014}
    }
License: rantalankilaSegments/Readme.txt (GNU General Public Licence)

[8] Selective Search:


    @ARTICLE{Uijlings13,
        author = {J.R.R. Uijlings and K.E.A. van de Sande and T. Gevers and A.W.M.
        Smeulders},
        title = {Selective Search for Object Recognition},
        journal = {International Journal of Computer Vision},
        year = {2013},
        doi = {10.1007/s11263-013-0620-5},
        owner = {jrruijli},
        timestamp = {2013.02.06},
        url = {http://www.huppelen.nl/publications/selectiveSearchDraft.pdf}
    }
License: selective_search/License.txt(Copyright University of Amsterdam)

[9] Evaluation Metrics:

    @INPROCEEDINGS{Hosang2014Bmvc,
        author = {J. Hosang and R. Benenson and B. Schiele},
        title = {How good are detection proposals, really?},
        booktitle = {BMVC},
        year = {2014}
    }
License: evaluation-metrics/LICENSE(GNU GENERAL PUBLIC LICENSE)

