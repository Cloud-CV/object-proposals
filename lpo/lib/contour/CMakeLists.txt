add_library( contour directedsobel.cpp boundarydetector.cpp structuredforest.cpp )
target_link_libraries( contour util imgproc learning )
