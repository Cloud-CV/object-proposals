if (UNIX)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -w")
endif()

add_subdirectory( boost )
add_subdirectory( ibfs )
add_subdirectory( floc )
add_subdirectory( liblbfgs-1.10 )
