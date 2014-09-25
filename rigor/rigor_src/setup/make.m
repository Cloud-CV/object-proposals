function make()
% script to mex internal code for RIGOR
%
% @authors:     Ahmad Humayun,  Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

tbb_incl_opt = '';
tbb_lib_opt = '';
boost_incl_opt = '';
boost_lib_opt = '';
extra_opts = '';

% set directories and options
if ispc
    % if windows
    tbb_dir = 'D:/tbb42';
    tbb_incl_dir = fullfile(tbb_dir, 'include');
    tbb_libs = fullfile(tbb_dir, 'lib/intel64/vc12');
    boost_dir = 'D:/boost/1.55.0/VC/11.0';
    boost_libs = fullfile(boost_dir, 'stage/lib');
    
    tbb_incl_opt = ['-I', tbb_incl_dir];
    tbb_lib_opt = ['-L', tbb_libs];
    boost_incl_opt = ['-I', boost_dir];
    boost_lib_opt = ['-L', boost_libs];
elseif ismac
    % if mac
else
    % if unix/linux
    boost_libs = '/usr/local/lib';
    boost_lib_opt = ['-L', boost_libs];
    extra_opts = '-lrt';
end

% find locations of files
code_root_dir = fullfile(fileparts(which(mfilename)), '..');
utils_dir = fullfile(code_root_dir, 'utils');
extern_dir = fullfile(code_root_dir, 'extern_src');
boykov_dir = fullfile(code_root_dir, 'boykov_maxflow');

% mex code
eval(sprintf('mex -O %s/intens_pixel_diff_mex.c -output %s/intens_pixel_diff_mex', utils_dir, utils_dir));
eval(sprintf('mex -O %s/prctile_feats.cpp -output %s/prctile_feats', utils_dir, utils_dir));
eval(sprintf('mex -O %s/region_centroids_mex.cpp -output %s/region_centroids_mex', utils_dir, utils_dir));
eval(sprintf('mex -O %s/superpix_regionprops.cpp -output %s/superpix_regionprops', utils_dir, utils_dir));
eval(sprintf('mex -O %s/sp_conncomp_mex.cpp %s -output %s/sp_conncomp_mex', utils_dir, boost_incl_opt, utils_dir));
eval(sprintf(['mex -O ', ...
    '%s/segm_overlap_mex.cpp ', ...
    '%s/overlap.cpp ', ...
    '-output %s/segm_overlap_mex'], utils_dir, utils_dir, utils_dir));
eval(sprintf('mex -O %s/convert_masks.cpp -output %s/convert_masks', utils_dir, utils_dir));
eval(sprintf(['mex -O ', ...
    '%s/overlap_over_threshold.cpp ', ...
    'CFLAGS="\\$CFLAGS -fopenmp" LDFLAGS="\\$LDFLAGS -fopenmp" ', ...
    '-output %s/overlap_over_threshold'], utils_dir, utils_dir));
eval(sprintf('mex -O %s/para_pseudoflow/hoch_pseudo_par.c -output %s/para_pseudoflow/hoch_pseudo_par', extern_dir, extern_dir));
eval(sprintf(['mex -O ', ...
    '%s/bk_dynamicgraphs_mex.cpp ', ...
    '%s/dynamicgraphs/bk_nodynamic.cpp ', ...
    '%s/dynamicgraphs/bk_kohli.cpp ', ...
    '%s/dynamicgraphs/bk_multiseeddynamic.cpp ', ...
    '%s/dynamicgraphs/bk_utils.cpp %s %s %s -ltbb ', ...
    'LDFLAGS="\\$LDFLAGS %s -lboost_system-mt -lboost_timer-mt %s" ', ...
    '-output %s/bk_dynamicgraphs_mex;'], ...
    boykov_dir, boykov_dir, boykov_dir, boykov_dir, boykov_dir, ...
    boost_incl_opt, tbb_incl_opt, tbb_lib_opt, boost_lib_opt, ...
    extra_opts, boykov_dir));

end