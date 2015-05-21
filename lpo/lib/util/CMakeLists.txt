add_library( util factory.cpp algorithm.cpp util.cpp eigen.cpp graph.cpp threading.cpp sse_defs.cpp optimization.cpp qp.cpp rasterize.cpp floc.cpp geodesics.cpp )
target_link_libraries( util lbfgs floc )
