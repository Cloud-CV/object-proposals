add_library( segmentation aggregation.cpp iouset.cpp segmentation.cpp gbs.cpp )
target_link_libraries( segmentation util learning imgproc contour )
