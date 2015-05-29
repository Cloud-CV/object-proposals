add_library( crf loss.cpp crf.cpp features.cpp objective.cpp )
target_link_libraries( crf util segmentation ibfs )
