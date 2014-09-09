object-proposals
================

This is a library/API which can be used to generate bounding box/region proposals using most of the existing object proposal approaches. 

File to note: 

config.json:

This file contains the settings needed to run any of the object proposal approaches. For each approach, the setings are stored as key-value pairs. Following is the description of the various settings: 
(all the strings and boolean values(true, false) should be enclosed in "double quotes").
	1) imageLocation: A string which contains the directory location of the images for whcih you want to generate proposals. 
 	2) outputLocation: A string whcih contains the directory location where you want to save the proposals.
	3) opts: You can optionally provide values for the keys in this object. 
		--numProposals: A number representing the number of proposals you want for each image.
    		--imageExt: A string storing the extension of the input images(for eg: ".JPEG", ".jpg" ) 
	 4) params: This contains specific parameters defined in each of the approaches. For more details about this key, refer to params.txt

Usage:
======

1) Open config.json. Set imageLocation, and outputLocation to locations of your choice for all the approaches you want to use. 

2) Run compile.m
( This compiles the approaches which require compiling and sets all the necessary paths)

3) Pick from one of the below to generate proposals to using a specific approach. The function names are self explanatory. 
For example, if you want to generate proposals using Selective Search, run calcSelectiveSearch.

Function names:
	1) calcEdgeBoxes 
	2) calcEndres
	3) calcMCG
	4) calcObjectness
	5) calcRahtu
	6) calcRaSegments
	7) calcRP
	8) calcSelectiveSearch

