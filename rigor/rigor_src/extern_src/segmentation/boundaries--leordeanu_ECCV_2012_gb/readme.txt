Gb code, version 1. October 4, 2012
author: Marius Leordeanu

Note: each function has explanations for its own input/output 

Main functions:

1. Gb_CSG( image ) - this is the main function, it outputs the gb boundaries using color, soft-segmentation, and geometric/contour features. It takes as input the color image 

2. softSegs( image ) - outputs the 8-layer soft-segmentation of the image, used by Gb

3. Gb_geom (edge_map, orientation) - it uses geometry/contour features to improve the egde strength values in the input thin edge_map

4. linkEgdes (edge_map, orientation) – links edges into contours

5. Gb_data_lambda (…) - general Gb function for any type and number of input layers, it outputs   the boundary strength for every pixel in the image, without nonmax supression and no final logistic classifier 

6. GbC_lambda (…) - same as Gb_data_lambda, but designed specifically for color layers

---------------------------------------------------------------------------
% This code is for research use only. 
% It is based on the following paper, which should be cited:
% Marius Leordeanu, Rahul Sukthankar and Cristian Sminchisescu, 
% "Efficient Closed-form Solution to Generalized Boundary Detection", 
% in ECCV 2012.
