// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

/* visualize.cpp */

#ifndef __VISUALIZEIMPL_HPP__
#define __VISUALIZEIMPL_HPP__

#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <boost/format.hpp>
#include <stdlib.h>

#include "graph.h"

#if defined(linux) || defined(__unix__)
#include <unistd.h>
#elif defined(_WIN32) || defined(WIN32)
#include <direct.h>
#endif

const std::string TEX_OUTPUT_PATH(
    "/home/ahumayun/Dropbox/cvpr2014_figs/boykov_graphs");

const std::string TEX_MAIN_FILE = "\\documentclass{article}\n\n"
    "\\usepackage[margin=1cm, twoside]{geometry}\n"
    "\\usepackage{amsmath}\n\\usepackage{amssymb}\n\\usepackage{etoolbox}\n"
    "\\usepackage{subfig}\n\\usepackage{multirow}\n\\usepackage{array}\n"
    "\\usepackage{tikz}\n\\usetikzlibrary{backgrounds}\n\n"
    "\\input{../header}\n\n"
    "\\begin{document}\n\n"
    "%s\n"
    "\\end{document}\n";

const std::string TIKZ_HEADER = "\\begin{figure*}[t]\n"
    "\\centering\n"
    "\\begin{tikzpicture}[scale=1.2]\n";
const std::string TIKZ_FOOTER = "\\end{tikzpicture}\n"
    "\\end{figure*}\n";

const unsigned int infty_thresh = 10000;

/*
 special constants for node->parent. Duplicated in graph.cpp, both should match!
 */
#define TERMINAL ( (arc *) 1 )    /* to terminal */
#define ORPHAN   ( (arc *) 2 )    /* orphan */

template<typename captype, typename tcaptype, typename flowtype>
void Graph<captype, tcaptype, flowtype>::get_node_r_c(
    const node* const node_ptr, unsigned int& node_idx, unsigned int& r,
    unsigned int& c, const int& NODE_ROWS) const {
  node_idx = node_ptr - nodes;
  r = NODE_ROWS - (node_idx % NODE_ROWS) - 1;
  c = node_idx / NODE_ROWS;
}

template<typename captype, typename tcaptype, typename flowtype>
  void Graph<captype, tcaptype, flowtype>::generate_pdf_graphs(
      const std::string& main_tex_filepath) const
{
  char orig_path[512];

  std::string out_filepath(main_tex_filepath + ".tex");

  std::cout << "Generating graph pdf" << std::endl;

  std::string main_out_path = TEX_OUTPUT_PATH + "/" + main_tex_filepath;
  std::ofstream main_tex_file(main_out_path.c_str(),
                              std::ios::out | std::ios::trunc);

  // collect all the graph files that were generated
  std::string graph_text = "";
  for (unsigned int i=0; i < graphs_vis_generated.size(); ++i) {
    graph_text = graph_text +
                 (boost::format("\\input{%s}\n") % graphs_vis_generated[i]).str();
  }

  main_tex_file << boost::format(TEX_MAIN_FILE) % graph_text << std::flush;
  main_tex_file.close();

  if (getcwd(orig_path, sizeof(orig_path)) == NULL)
    perror("getcwd() error");

  int result = chdir(TEX_OUTPUT_PATH.c_str());

#if defined(linux) || defined(__unix__)
  /* run pdflatex command on the new tex graph file */
  FILE* fp = popen(("pdflatex " + main_tex_filepath).c_str(), "r");
  if (fp == NULL)
    std::cerr << "Couldn''t create pdf" << std::endl;
  std::string cur_string = "";
  const int SIZEBUF = 1234;
  char buf[SIZEBUF];
  while (fgets(buf, sizeof(buf), fp)) {
    cur_string += buf;
  }
  pclose(fp);
#endif
  
  //std::cout << cur_string << std::endl;

  result = chdir(orig_path);

  std::cout << "Done generating pdf: " << main_out_path << std::endl;
}

template<typename captype, typename tcaptype, typename flowtype>
  void Graph<captype, tcaptype, flowtype>::generate_graph_visualization(
      const unsigned int& NODE_ROWS, const std::string& graph_filename)
{
  unsigned int node_idx, node_idx2, r, c, r2, c2;
  std::string node_type, curr_cap;
  std::stringstream output_stream;
  bool no_rev_arc;

  node* node_ptr;
  arc* arc_ptr;

  output_stream << TIKZ_HEADER;

  /* iterate over all nodes */
  for (node_ptr = nodes; node_ptr < node_last; ++node_ptr) {
    get_node_r_c(node_ptr, node_idx, r, c, NODE_ROWS);

    // convert residual capacity into a string
    std::ostringstream convert;
    convert << node_ptr->tr_cap;
    curr_cap = convert.str();
    if (abs(node_ptr->tr_cap) > infty_thresh)
      curr_cap = "\\infty";

    if (node_ptr->parent != NULL || node_ptr->parent == ORPHAN ) {
      if (node_ptr->is_sink)
        node_type = "bgnode";
      else {
        if (node_ptr->src_origin_idx == INVALID_SRC_ID)
          node_type = "fgnode";
        else {
          convert.str("");
          convert << "fg" << node_ptr->src_origin_idx+1 << "node";
          node_type = convert.str();
        }
      }
    } else {
      node_type = "varnode";
    }

    output_stream
        << boost::format(
            "\\node[%s] (%d) at (%d,%d) {\\nodetxt{%d}{$%s$}{}};\n") % node_type
            % (node_idx + 1) % c % r % (node_idx + 1) % curr_cap;

    /*
    convert.str("");
    convert << "SOURCE - " << node_ptr->src_origin_idx << "";
    std::string sink_src = node_ptr->is_sink ? "SINK" : convert.str();

    std::cout << (node_idx + 1) << ": ";

    if (node_ptr->parent == NULL)
      std::cout << "NULL parent\n";
    else if (node_ptr->parent == TERMINAL )
      std::cout << boost::format("Parent is TERMINAL (%s)\n") % sink_src;
    else if (node_ptr->parent == ORPHAN )
      std::cout << "Orphan\n";
    else {
      node_idx2 = node_ptr->parent->head - nodes;
      std::cout
        << boost::format("Parent node: %d (%s)\n") % (node_idx2 + 1)
           % sink_src;
    }
    */
  }

  output_stream << std::endl;

  for (arc_ptr = arcs; arc_ptr < arc_last; ++arc_ptr) {
    node* start_node = arc_ptr->sister->head;
    node* end_node = arc_ptr->head;

    get_node_r_c(start_node, node_idx, r, c, NODE_ROWS);
    get_node_r_c(end_node, node_idx2, r2, c2, NODE_ROWS);

    no_rev_arc = (arc_ptr->sister->r_cap == 0);

    // convert residual capacity into a string
    std::ostringstream convert;
    convert << arc_ptr->r_cap;
    curr_cap = convert.str();

    bool do_draw = true;
    bool is_sink_tree_node = start_node->parent != NULL &&
                             start_node->parent != ORPHAN &&
                             start_node->parent != TERMINAL &&
                             start_node->is_sink &&
                             start_node->parent->head == end_node;
    bool end_is_sink_tree_node = end_node->parent != NULL &&
                                 end_node->parent != ORPHAN &&
                                 end_node->parent != TERMINAL &&
                                 end_node->is_sink &&
                                 end_node->parent->head == start_node;
    bool is_source_tree_node = end_node->parent != NULL &&
                               start_node->parent != ORPHAN &&
                               end_node->parent != TERMINAL &&
                               !end_node->is_sink &&
                               end_node->parent->head == start_node;
    bool end_is_source_tree_node = start_node->parent != NULL &&
                                   end_node->parent != ORPHAN &&
                                   start_node->parent != TERMINAL &&
                                   !start_node->is_sink &&
                                   start_node->parent->head == end_node;
    if (arc_ptr->r_cap > 0) {
      std::string appender = "";

      if (!no_rev_arc) {
        // if reverse arc exists
        // first find what direction is it
        if (arc_ptr->r_cap == arc_ptr->sister->r_cap &&
            !is_sink_tree_node && !is_source_tree_node &&
            !end_is_sink_tree_node && !end_is_source_tree_node) {
          // in case of same capacity draw only one arc (if not part of
          // the sink tree - in which case draw both)
          if (node_idx > node_idx2)
            do_draw = false;
        }
        else if (r == r2+1 && c == c2)
          appender += ", n to s";
        else if (r+1 == r2 && c == c2)
          appender += ", s to n";
        else if (r == r2 && c+1 == c2)
          appender += ", w to e";
        else if (r == r2 && c2+1 == c)
          appender += ", e to w";
        else if (c + 1 == c2 && r + 1 == r2)
          appender += ", sw to ne";
        else if (c2 + 1 == c && r2 + 1 == r)
          appender += ", ne to sw";
        else if (c + 1 == c2 && r == r2 + 1)
          appender += ", nw to se";
        else if (c2 + 1 == c && r2 == r + 1)
          appender += ", se to nw";
      } else {
        appender += ", arrows=->";
      }

      if (is_sink_tree_node)
        appender += ", ttree";

      if (is_source_tree_node) {
        if (end_node->src_origin_idx == INVALID_SRC_ID)
          appender += ", stree";
        else {
          convert.str("");
          convert << ", s" << end_node->src_origin_idx+1 << "tree";
          appender += convert.str();
        }
      }

      if (do_draw)
        output_stream
            << boost::format("\\draw[conn=%s%s] (%d) to (%d);\n") % curr_cap
                % appender % (node_idx + 1) % (node_idx2 + 1);
    }
  }

  output_stream << TIKZ_FOOTER;

  //std::cout << output_stream.rdbuf();

  // generate tex graph file
  std::string out_filepath(graph_filename + ".tex");
/*
  if (!fs::exists(TEX_OUTPUT_PATH))
    fs::create_directories(TEX_OUTPUT_PATH);
    */
  std::string graph_out_path = TEX_OUTPUT_PATH + "/" + out_filepath;

  std::ofstream graph_tikz_file(graph_out_path.c_str(),
                                std::ios::out | std::ios::trunc);
  graph_tikz_file << output_stream.rdbuf() << std::flush;
  graph_tikz_file.close();

  graphs_vis_generated.push_back(graph_filename);
}

#endif