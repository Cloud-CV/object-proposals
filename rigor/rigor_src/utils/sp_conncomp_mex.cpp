// Used for computing the connected components in a superpixel graph and 
// filtering components whose total (pixel) size less than a certain 
// threshold.
//
// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "mex.h"
#include <boost/config.hpp>
#include <iostream>
#include <vector>
#include <algorithm>
#include <utility>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/filtered_graph.hpp>
#include <boost/graph/connected_components.hpp>
#include <boost/graph/graph_utility.hpp>


template <typename TGraph>
struct vertex_id_filter
{
  vertex_id_filter() : _segment(NULL) {}
  
  vertex_id_filter(const mxLogical* segment) : _segment(segment) {}
  
  bool operator()(const typename boost::graph_traits<TGraph>::vertex_descriptor& v) const {
    return _segment[v]; // keep all vertx_descriptors nodes which belong to this segment
  }
  
 private:
  const mxLogical* _segment;
};

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  unsigned int i, j, curr_idx, curr_comp_idx, total_comp = 0, comp_iter, old_comp_id, comp_num, comp_offset;
  double* edgelet_pairs, *conn_comp_ptr, *num_components, *sp_seg_szs=NULL;
  double min_sz;
  mxLogical* segments;
  mxLogical* new_segments;
  mxArray* conn_comp;
  
  typedef boost::adjacency_list <boost::vecS, boost::vecS, boost::undirectedS> Graph;
  typedef boost::filtered_graph<Graph, boost::keep_all, vertex_id_filter<Graph> > FilteredGraphType;
  
  FilteredGraphType::vertex_iterator fi, fi2, fi_end;
  
  Graph sp_graph;
  
  if (nrhs != 2 && nrhs != 4) {
    mexErrMsgTxt("Needs 2 or 4 input variables: \n"
                 "sp_conncomp_mex(segments, edgelet_pairs): where segments is an nxm segments matrix of n superpixels and m segments, and edglet_pairs is the px2 edges in the superpixel graph\n"
                 "sp_conncomp_mex(segments, edgelet_pairs, sp_seg_szs, min_sz): where sp_seg_szs is a vector of size nx1, and min_sz is a double scalar indicating what is the minimum size of a segment below which everything will be filtered");
  }
  if (nlhs != 2) {
    mexErrMsgTxt("Only outputs 1 variable: new_segments = sp_conncomp_mex(segments, edgelet_pairs) where new_segments is the nxs segments matrix");
  }
  
  if (!mxIsLogical(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 2) {
    mexErrMsgTxt("segments should be a matrix of type logical");
  }
  if (!mxIsDouble(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2 ||
          mxGetN(prhs[1]) != 2) {
    mexErrMsgTxt("edgelet_pairs should be a px2 double matrix");
  }
  if (nrhs == 4 && (!mxIsDouble(prhs[2]) || 
          mxGetNumberOfDimensions(prhs[2]) != 2 ||
          mxGetN(prhs[2]) != 1 || mxGetM(prhs[0]) != mxGetM(prhs[2]))) {
    mexErrMsgTxt("sp_seg_szs should be a mx1 double vector of segment sizes");
  }
  if (nrhs == 4 && (!mxIsDouble(prhs[3]) || 
          mxGetNumberOfDimensions(prhs[3]) != 2 ||
          mxGetM(prhs[3]) != 1 || mxGetN(prhs[3]) != 1)) {
    mexErrMsgTxt("min_sz should be a scalar double giving the minimum acceptable size of a connected component");
  }
  
  segments = (mxLogical*)mxGetData(prhs[0]);
  size_t num_sps = mxGetM(prhs[0]);
  size_t num_segs = mxGetN(prhs[0]);
  
  size_t num_edges = mxGetM(prhs[1]);
  edgelet_pairs = (double*)mxGetData(prhs[1]);
  
  if (nrhs == 4) {
    /* If sp_seg_szs and min_sz provided */
    sp_seg_szs = (double*) mxGetData(prhs[2]);
    min_sz =  *((double*)mxGetData(prhs[3]));
  }
  
  /*mexPrintf("%dx%d = %dx2\n", num_sps, num_segs, num_edges);*/
  
  /* make the superpixel graph */
  for (i = 0; i < num_edges; ++i) {
    boost::add_edge(edgelet_pairs[i]-1, edgelet_pairs[i+num_edges]-1, sp_graph);
  }
  
  std::vector<int> component(boost::num_vertices(sp_graph));
  
  std::vector<unsigned int> comp_sz(num_sps);
  std::vector<unsigned int> comp_ids(num_sps);
  
  plhs[1] = mxCreateDoubleMatrix(num_segs, 1, mxREAL);
  num_components = (double*)mxGetData(plhs[1]);
  
  conn_comp = mxCreateDoubleMatrix(num_sps, num_segs, mxREAL);
  conn_comp_ptr = (double*)mxGetData(conn_comp);
  
  /* iterate over each segment */
  for (i = 0; i < num_segs; ++i) {
    curr_idx = i*num_sps;
    
    /* induce a graph by removing the nodes not in this segment */
	vertex_id_filter<Graph> filter(segments + curr_idx);
    FilteredGraphType fg_segment(sp_graph, boost::keep_all(), filter);
    
    /* find the connected components in this graph - the first component 
     * in the component vector would be 0, and so on (the nodes not in the
     * induced subgraph would also be 0). This command also sets the output
     * num_components array (second return variable) */
    num_components[i] = boost::connected_components(fg_segment, &component[0]);
    /*std::cout << "Total number of components: " << i << " " << num_components[i] << std::endl;*/
    
    /* set the component sizes to 0, and the component ids (will come handy
     * later when we need to remove components below the minimum size) */
    if (sp_seg_szs) {
      for (j = 0; j < num_components[i]; ++j) {
        comp_sz[j] = 0;
        comp_ids[j] = j + 1;
      }
    }
    
    /* iterate over each superpixel in the induced subgraph and set the
     * component id in in conn_comp(:,i) */
    boost::tie(fi, fi_end) = vertices(fg_segment);
    fi2 = fi;
    for (; fi != fi_end; ++fi) {
      j = *fi;
      /* set the component id for the current sp */
      conn_comp_ptr[curr_idx + j] = component[j] + 1;

      /* Add to the component size */
      if (sp_seg_szs) {
        comp_sz[component[j]] += sp_seg_szs[j];
      }
    }
    
    if (sp_seg_szs) {
      fi = fi2;
      /* iterate over each sp and see if it belongs to a component whose
       * size is below min_sz */
      for (; fi != fi_end; ++fi) {
        /* check to which component this sp belongs */
        curr_comp_idx = conn_comp_ptr[curr_idx + *fi] - 1;
        
        /* check component size - if below min_sz, remove component and sp
         * from the set of components */
        if (comp_sz[curr_comp_idx] < min_sz) {
            comp_ids[curr_comp_idx] = 0;
            conn_comp_ptr[curr_idx + *fi] = 0;
        }
      }
      
      /* iterate over each component and renumber their ids accordingly */
      comp_iter = 0;
      for (j = 0; j < num_components[i]; ++j) {
        if (comp_ids[j] != 0) {
          /* if component remains */
          ++comp_iter;
          /* if component id needs to be shifted forward (decrease id 
           * because some component(s) removed due to small size) */
          old_comp_id = comp_ids[j];
          if (old_comp_id != comp_iter) {
            comp_ids[j] = comp_iter;
            fi = fi2;
            /* iterate over all superpixels to see which ones need their 
             * component id renumbered */
            for (; fi != fi_end; ++fi) {
              /* if superpixel belongs to the component being renumbered */
              if (conn_comp_ptr[curr_idx + *fi] == old_comp_id) {
                conn_comp_ptr[curr_idx + *fi] = comp_iter;
              }
            }
          }
        }
      }
      
      /* set number of components according to how many are remaining */
      num_components[i] = comp_iter;
    }
    
    total_comp += num_components[i];
  }
  
  /* create the matrix for the return variable, which contains a connected 
   * component in each column */
  plhs[0] = mxCreateLogicalMatrix(num_sps, total_comp);
  new_segments = (mxLogical*)mxGetData(plhs[0]);
  
  /* expand the connected components to a logical matrix for output */
  comp_iter = 0;
  for (i = 0; i < num_segs; ++i) {
    curr_idx = i*num_sps;
    curr_comp_idx = comp_iter*num_sps;
    
    /* expand the current segment into its components */
    for (j = 0; j < num_sps; ++j) {
      /* get the component number for the sp for the current segment  */
      comp_num = conn_comp_ptr[curr_idx + j];
      
      /* if the sp was in some component */
      if (comp_num != 0) {
        /* set the sp in the relevant component */
        comp_offset = curr_comp_idx + (comp_num - 1)*num_sps; 
        new_segments[comp_offset + j] = 1;
      }
    }
    
    comp_iter += num_components[i];
  }
  
  /*std::cout << "Total components: " << total_comp << std::endl;*/
  
  mxDestroyArray(conn_comp);
}
