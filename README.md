Object-proposals:
================

This is a library/API which can be used to generate bounding box/region proposals using most of the existing object proposal approaches.


Usage:
======

1. Open config.json. Set imageLocation, and outputLocation to locations of your choice for all the approaches you want to use. (All other config values have been set to default values)

2. Run compile.m
( This compiles the approaches which require compiling and sets all the necessary paths)

3. Pick from one of the below to generate proposals to using a specific approach. The function names are self explanatory.
For example, if you want to generate proposals using Selective Search, run calcSelectiveSearch.

Function names:
    
* calcEdgeBoxes    
*  calcEndres  
*  calcMCG  
*  calcObjectness  
*  calcRahtu  
*  calcRaSegments  
*  calcRP  
*  calcSelectiveSearch

File to note: config.json
==================
This file contains the settings needed to run any of the object proposal approaches. For each approach, the setings are stored as key-value pairs. Following is the description of the various settings:
(all the strings should be enclosed in "double quotes", boolean variables should be without quoteslike eg. true, false ).  
  
* imageLocation: A string which contains the directory location of the images for whcih you want to generate proposals.    
* outputLocation: A string whcih contains the directory location where you want to save the proposals.  
* opts: You can optionally provide values for the keys in this object.  

 - numProposals: A number representing the number of proposals you want for each image.  
 - imageExt: A string storing the extension of the images in the imageLocation folder. (for eg: ".JPEG", ".jpg" )

* params: This contains specific parameters defined in each of the approaches. For more details about this key, refer to params.txt

License:
==================
The original license for each object proposal has been retained in their respective folders. Please refer to individual license before using the specific object proposal.


Citations
==================
This package contain various object proposal implementations of the algorithms presented in the following papers. If you are using object proposals presented in these papers, we request you to cite appropriate papers:

1. EdgeBoxes:  
@inproceedings{DollarICCV13edges,
  author    = {Piotr Doll\'ar and C. Lawrence Zitnick},
  title     = {Structured Forests for Fast Edge Detection},
  booktitle = {ICCV},
  year      = {2013},
}

@article{DollarARXIV14edges,
  author    = {Piotr Doll\'ar and C. Lawrence Zitnick},
  title     = {Fast Edge Detection Using Structured Forests},
  journal   = {ArXiv},
  year      = {2014},
}

@inproceedings{ZitnickECCV14edgeBoxes,
  author    = {C. Lawrence Zitnick and Piotr Doll\'ar},
  title     = {Edge Boxes: Locating Object Proposals from Edges},
  booktitle = {ECCV},
  year      = {2014},
}

2. Endres - Category Independent Object Proposals:    
@article{10.1109/TPAMI.2013.122,
author = {Ian Endres and Derek Hoiem},
title = {Category-Independent Object Proposals with Diverse Ranking},
journal ={IEEE Transactions on Pattern Analysis and Machine Intelligence},
volume = {36},
number = {2},
issn = {0162-8828},
year = {2014},
pages = {222-234},
doi = {http://doi.ieeecomputersociety.org/10.1109/TPAMI.2013.122},
publisher = {IEEE Computer Society},
address = {Los Alamitos, CA, USA},
}

3. MCG: Multiscale Combinatorial Grouping:  
@inproceedings{APBMM2014,
  author = {Arbel\'{a}ez, P. and Pont-Tuset, J. and Barron, J. and Marques, F. and Malik, J.},
  title = {Multiscale Combinatorial Grouping},
  booktitle = {Computer Vision and Pattern Recognition},
  year = {2014}
}

4. Objectness: 
@string{pami="IEEE Transactions on Pattern Analysis and Machine Intelligence (TPAMI)"}
@string{calvinroot="http://groups.inf.ed.ac.uk/calvin/"}
@Article{Alexe2012pami,
  author = {Alexe, Bogdan and Deselaers, Thomas and Ferrari, Vittorio},
  title = {Measuring the objectness of image windows },
  journal = pami,
  year = 2012,
  url = calvinroot # {objectness/},
  pdf = calvinroot # {Publications/alexe12pami.pdf},
}

5. Rahtu:  
@inproceedings{DBLP:conf/iccv/RahtuKB11,
  author    = {Esa Rahtu and
               Juho Kannala and
               Matthew B. Blaschko},
  title     = {Learning a category independent object detection cascade},
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
@inproceedings{DBLP:conf/cvpr/AlexeDF10,
  author    = {Bogdan Alexe and
               Thomas Deselaers and
               Vittorio Ferrari},
  title     = {What is an object?},
  booktitle = {The Twenty-Third {IEEE} Conference on Computer Vision and Pattern
               Recognition, {CVPR} 2010, San Francisco, CA, USA, 13-18 June 2010},
  year      = {2010},
  pages     = {73--80},
  crossref  = {DBLP:conf/cvpr/2010},
  url       = {http://dx.doi.org/10.1109/CVPR.2010.5540226},
  doi       = {10.1109/CVPR.2010.5540226},
  timestamp = {Fri, 19 Sep 2014 06:13:54 +0200},
  biburl    = {http://dblp.uni-trier.de/rec/bib/conf/cvpr/AlexeDF10},
  bibsource = {dblp computer science bibliography, http://dblp.org}
}  
@article{DBLP:journals/ijcv/FelzenszwalbH04,
  author    = {Pedro F. Felzenszwalb and
               Daniel P. Huttenlocher},
  title     = {Efficient Graph-Based Image Segmentation},
  journal   = {International Journal of Computer Vision},
  year      = {2004},
  volume    = {59},
  number    = {2},
  pages     = {167--181},
  url       = {http://dx.doi.org/10.1023/B:VISI.0000022288.19776.77},
  doi       = {10.1023/B:VISI.0000022288.19776.77},
  timestamp = {Fri, 19 Sep 2014 06:14:48 +0200},
  biburl    = {http://dblp.uni-trier.de/rec/bib/journals/ijcv/FelzenszwalbH04},
  bibsource = {dblp computer science bibliography, http://dblp.org}
}  

6. Randomized Prims:  
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

7. Rantalankila:  
@InProceedings{Rantalankila_2014_CVPR,
author = {Rantalankila, Pekka and Kannala, Juho and Rahtu, Esa},
title = {Generating Object Segmentation Proposals using Global and Local Search},
journal = {The IEEE Conference on Computer Vision and Pattern Recognition (CVPR)},
month = {June},
year = {2014}
}

8. Selective Search:
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

9. Evaluation Metrics:  
@INPROCEEDINGS{Hosang2014Bmvc,
  author = {J. Hosang and R. Benenson and B. Schiele},
  title = {How good are detection proposals, really?},
  booktitle = {BMVC},
  year = {2014}
}