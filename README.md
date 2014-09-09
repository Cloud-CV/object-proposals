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
