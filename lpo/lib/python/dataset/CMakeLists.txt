if (NOT DEFINED DATA_DIR)
	set (DATA_DIR "" CACHE STRING "Common data directory" FORCE)
endif()
if (NOT "${DATA_DIR}" STREQUAL "")
	file(TO_CMAKE_PATH ${DATA_DIR}/BSDS500 TMP)
	add_definitions( -DBERKELEY_DIR=${TMP} )

	file(TO_CMAKE_PATH ${DATA_DIR}/COCO TMP)
	add_definitions( -DCOCO_DIR=${TMP} )

	file(TO_CMAKE_PATH ${DATA_DIR}/NYU TMP)
	add_definitions( -DNYU_DIR=${TMP} )

	file(TO_CMAKE_PATH ${DATA_DIR}/weizmann_horse_db TMP)
	add_definitions( -DWEIZMANN_DIR=${TMP} )

	file(TO_CMAKE_PATH ${DATA_DIR} TMP)
	add_definitions( -DVOC_DIR=${TMP} )
endif()

include_directories( ${ZLIB_INCLUDE_DIRS} )

add_library( dataset apng.cpp berkeley.cpp boundary.cpp coco.cpp voc.cpp evaluation.cpp )#nyu.cpp voc.cpp apng.cpp berkeley.cpp evaluation.cpp covering.cpp weizmann.cpp coco.cpp grabcut.cpp )
target_link_libraries( dataset imgproc ${Boost_LIBRARIES} ${PYTHON_LIBRARIES} ${ZLIB_LIBRARIES} )
