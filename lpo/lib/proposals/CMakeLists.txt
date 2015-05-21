file(GLOB LPO_SOURCES lpo/*.cpp)

add_library( proposals seed.cpp seedfeature.cpp proposal.cpp lpo.cpp ${LPO_SOURCES} )
target_link_libraries( proposals util learning imgproc contour lbfgs segmentation )
