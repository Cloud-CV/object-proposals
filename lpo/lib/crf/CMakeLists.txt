add_library( crf loss.cpp crf.cpp crffeatures.cpp objective.cpp )
target_link_libraries( crf util segmentation ibfs )
