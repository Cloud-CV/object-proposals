// @authors:     Ahmad Humayun
// @contact:     ahumayun@cc.gatech.edu
// @affiliation: Georgia Institute of Technology
// @date:        Fall 2013 - Summer 2014

#include "bk_dynamicgraphs.h"


void gather_seed_nums(const size_t& num_seeds, const size_t& num_vars,
                      std::vector<int>& fg_seed_nums,
                      const unarycaptype* const nonlambda_s,
                      const unarycaptype* const nonlambda_t)
{
  fg_seed_nums.assign(num_seeds, 0);

  size_t idx = 0;
  for (size_t s=0; s < num_seeds; ++s) {
    /* iterate over all nodes in the current seed graph */
    for (GraphType::node_id var_i=0; var_i < num_vars; ++var_i, ++idx) {
      /* see if the current variable is a seed pixel */
      if (nonlambda_s[idx] >= INF_SEED_THRESH) {
        ++fg_seed_nums[s];
      }
    }
  }
}

void gather_seed_vars(const size_t& num_seeds, const size_t& num_vars,
                      GraphType::FGSeedsType* const fg_seeds,
                      fgseedmaptype* const fg_seed_map,
                      const unarycaptype* const nonlambda_s,
                      const unarycaptype* const nonlambda_t)
{
  fg_seeds->assign(num_seeds, GraphType::SrcSeedList());

  size_t idx = 0;
  /* iterate over all seeds */
  for (size_t s=0; s < num_seeds; ++s) {
    GraphType::SrcSeedList curr_src_seeds;
    /* std::cout << "Seed:" << s; */
    /* iterate over all nodes in the current seed graph */
    for (GraphType::node_id var_i=0; var_i < num_vars; ++var_i, ++idx) {
      /* see if the current variable is a seed pixel */
      if (nonlambda_s[idx] >= INF_SEED_THRESH) {
        GraphType::NodeCap nic(nonlambda_s[idx], 0);
        GraphType::SrcSeedNode ssn(var_i, nic);
        curr_src_seeds.push_back(ssn);

        (*fg_seed_map)[var_i] = fgseedmapvaltype(s, curr_src_seeds.size()-1);

        //std::cout << "\tNode id:" << var_i << " : " << s << std::endl;
      }
    }

    (*fg_seeds)[s] = curr_src_seeds;
  }
}


int change_cut_for_var(const GraphType* const g, resulttype* const cuts,
                        const GraphType::node_id& var_i,
                        const unsigned int& lambda_idx, const bool REV=false)
{
  char changed = 0;

  /* supposes that cuts can only grow */
  if (REV) {
    if (cuts[var_i] == 0) {
      if (g->what_segment(var_i) == GraphType::SINK) {
        cuts[var_i] = lambda_idx+1;
        changed = -1;
      }
    }
  } else {
    if (cuts[var_i] == 0) {
      if (g->what_segment(var_i) == GraphType::SOURCE) {
        cuts[var_i] = lambda_idx+1;
        changed = 1;
      }
    }
  }

  return changed;
}

void update_cut(GraphType* const g, resulttype* const cuts,
                const unsigned int lambda_idx, unsigned int& in_src_cut,
                Block<GraphType::node_id>* const changed_list, const bool REV)
{
  if (changed_list) {
    GraphType::node_id* ptr;
    for (ptr=changed_list->ScanFirst(); ptr; ptr=changed_list->ScanNext()) {
      GraphType::node_id var_i = *ptr;
      in_src_cut += change_cut_for_var(g, cuts, var_i, lambda_idx, REV);
      g->remove_from_changed_list(var_i);
    }
    changed_list->Reset();
  } else {
    /* get the variables which changed to the src side fo the cut */
    for (GraphType::node_id var_i = 0; var_i < g->get_node_num(); ++var_i) {
      in_src_cut += change_cut_for_var(g, cuts, var_i, lambda_idx, REV);
    }
  }
}
