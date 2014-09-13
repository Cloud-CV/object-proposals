// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include <boost/program_options.hpp>
#include <iostream>
#include "graph.h"
#include "examples/examples.h"
#include "tests/tests.h"

namespace po = boost::program_options;

int main(int argc, char* argv[]) {
  po::options_description desc("Allowed options and parameters");
  desc.add_options()
      ("help,h",                                     "produce help message")
      ("runexample,r",     po::value<int>(),         "run an example graph")
      ("genexample,g",     po::value<int>(),         "(1) generate multiseed example graph; (2) to produce multi-section graph")
      ("testdynamic,t",                              "test Kohli dynamic graphs")
      ("testdeepcpy,c",                              "test deep copy of graphs")
      ("testseedsolve,s",                            "test solving graphs with multiple seeds initialized by a precomputation step");

  try {
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);

    if (vm.count("help")) {
      std::cerr << desc << std::endl;
      return 0;
    }

    po::notify(vm);

    if (vm.count("runexample")) {
      int example_no = vm["runexample"].as<int>();

      switch (example_no) {
        case 1:
          example1();
          break;
        case 2:
          example2();
          break;
        case 3:
          example3();
          break;
        case 4:
          example4();
          break;
        case 5:
          example5();
          break;
      }
    } else if (vm.count("genexample")) {
      int example_no = vm["genexample"].as<int>();

      switch (example_no) {
        case 1:
          search_example_graph();
          break;
        case 2:
          search_example_graph2();
          break;
      }
    } else if (vm.count("testdynamic")) {
      dynamicgraph_test();
    } else if (vm.count("testdeepcpy")) {
      test_deepcopy();
    } else if (vm.count("testseedsolve")) {
      test_seedsolve();
    } else {
      std::cerr << desc << std::endl;
    }
  } catch (po::error& e) {
    std::cerr << "Program Options error: " << e.what() << std::endl;
    std::cerr << desc << std::endl;
    return -1;
  } catch (std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return -1;
  } catch (...) {
    std::cerr << "Unknown error!" << std::endl;
    return -1;
  }

  return 0;
}
