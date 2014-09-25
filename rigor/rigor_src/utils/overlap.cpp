/* Copyright (C) 2010 Joao Carreira

 This code is part of the extended implementation of the paper:
 
 J. Carreira, C. Sminchisescu, Constrained Parametric Min-Cuts for Automatic Object Segmentation, IEEE CVPR 2010

Fuxin Li mod Jan 28, 2013, improved speed by 2x by reducing memory references.
 */

#include <omp.h>
#include <mex.h>

void overlap(unsigned int *intersections, unsigned int *reunions, bool *segms, int nc, int nr) {
    int i;
    
#pragma omp parallel for
    for(i=0; i<nc; ++i) { /* for each segment */
        int j, index_ij, index_ik, index_jk, k, res_int, res_uni;
        index_ij = i * (nc +1)+1;
        for(j=i+1; j<nc; ++j) { /* go through the others with j>i */
            index_ik = i*nr;
            index_jk = j*nr;
            res_int = 0;
            res_uni = 0;
            for(k=0; k<nr; ++k) { /* compute intersections and reunions */
                res_int += (segms[index_ik] & segms[index_jk]);
                res_uni += (segms[index_ik] | segms[index_jk]);
	            ++index_ik;
                ++index_jk;
            }
            intersections[index_ij] = res_int;
            reunions[index_ij] = res_uni;
            ++index_ij;
        }
	}
    return;
}

void overlap(unsigned int *intersections, unsigned int *reunions, bool *segms, bool *segms2, int nc, int nc2, int nr) {
    int i;
    
#pragma omp parallel for
    for(i=0; i<nc; ++i) { /* for each segment */
        int j, index_ij, index_ik, index_jk, k, res_int, res_uni;
        index_ij = i * (nc2);
        for(j=0; j<nc2; ++j) { /* go through the others with j>i */
            index_ik = i*nr;
            index_jk = j*nr;
            res_int = 0;
            res_uni = 0;
            for(k=0; k<nr; ++k) { /* compute intersections and reunions */
                res_int += (segms[index_ik] & segms2[index_jk]);
                res_uni += (segms[index_ik] | segms2[index_jk]);
	            ++index_ik;
                ++index_jk;
            }
            intersections[index_ij] = res_int;
            reunions[index_ij] = res_uni;
            ++index_ij;
        }
	}
    return;
}

void overlap_sp(unsigned int *intersections, unsigned int *reunions, bool *segms, unsigned int *sp_seg_sz, int nc, int nr) {
    int i;
    
#pragma omp parallel for
    for(i=0; i<nc; ++i) { /* for each segment */
        int j, index_ij, index_ik, index_jk, k, res_int, res_uni;
        index_ij = i * (nc +1)+1;
        for(j=i+1; j<nc; ++j) { /* go through the others with j>i */
            index_ik = i*nr;
            index_jk = j*nr;
            res_int = 0;
            res_uni = 0;
            for(k=0; k<nr; ++k) { /* compute intersections and reunions */
                res_int += (segms[index_ik] & segms[index_jk]) * sp_seg_sz[k];
                res_uni += (segms[index_ik] | segms[index_jk]) * sp_seg_sz[k];
	            ++index_ik;
                ++index_jk;
            }
            intersections[index_ij] = res_int;
            reunions[index_ij] = res_uni;
            ++index_ij;
        }
	}
    return;
}

void overlap_sp(unsigned int *intersections, unsigned int *reunions, bool *segms, bool *segms2, unsigned long *sp_seg_sz, int nc, int nc2, int nr) {
    int i;
    
#pragma omp parallel for
    for(i=0; i<nc; ++i) { /* for each segment */
        int j, index_ij, index_ik, index_jk, k, res_int, res_uni;
        index_ij = i * (nc2);
        for(j=0; j<nc2; ++j) { /* go through the others with j>i */
            index_ik = i*nr;
            index_jk = j*nr;
            res_int = 0;
            res_uni = 0;
            for(k=0; k<nr; ++k) { /* compute intersections and reunions */
                res_int += (segms[index_ik] & segms2[index_jk]) * sp_seg_sz[k];
                res_uni += (segms[index_ik] | segms2[index_jk]) * sp_seg_sz[k];
	            ++index_ik;
                ++index_jk;
            }
            intersections[index_ij] = res_int;
            reunions[index_ij] = res_uni;
            ++index_ij;
        }
	}
    return;
}