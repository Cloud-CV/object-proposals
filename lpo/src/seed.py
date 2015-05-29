# -*- encoding: utf-8
"""
    Copyright (c) 2015, Philipp Krähenbühl
    All rights reserved.
	
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
        * Neither the name of the Stanford University nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.
	
    THIS SOFTWARE IS PROVIDED BY Philipp Krähenbühl ''AS IS'' AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL Philipp Krähenbühl BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
from lpo import *
from util import *
import numpy as np

def trainSeed( N_SEED=250, shrink=0.25, detector='mssf', min_size=0, max_size=1, n_seed_per_obj=1 ):
	print("Training seeds")
	print("  * Loading dataset")
	over_segs,segmentations,boxes,names = loadVOCAndOverSeg( "train", detector=detector )
	print("  * Reprojecting ")
	psegs = [over_seg.projectSegmentation( seg+1 )-1 for over_seg,seg in zip(over_segs,segmentations)]

	print("  * Shrinking segments")
	# Shrink each of the segments by about 50% [if possible]
	pseg_to_use = util.VecVectorXs()
	over_seg_to_use = segmentation.VecImageOverSegmentation()
	for over_seg,pseg in zip(over_segs,psegs):
		N,M = pseg.shape[0],np.max(pseg)+1
		# Find the distance to the object boundary (for each object)
		d = -np.ones( N )
		if shrink < 1:
			adj_list = [[] for i in range(N)]
			from queue import Queue
			q = Queue()
			for e in over_seg.edges:
				if pseg[e.a] != pseg[e.b]:
					q.put((e.a,0))
					q.put((e.b,0))
				else:
					adj_list[e.a].append( e.b )
					adj_list[e.b].append( e.a )
			d[ pseg<0 ] = 0
			while not q.empty():
				n,l = q.get()
				if d[n] >= 0:
					continue
				d[n] = l
				for i in adj_list[n]:
					if d[i]==-1:
						q.put((i,l+1))
		# Find the distance distribution for each object
		for l in range(M):
			dd = d[ pseg==l ]
			if dd.size > over_seg.Ns*max_size or dd.size < over_seg.Ns*min_size:
				pseg[ pseg==l ] = -2
			elif shrink < 1 and dd.shape[0]>0:
				t = np.sort(dd)[int(shrink*dd.shape[0])]
				pseg[ np.logical_and( pseg==l, d<t ) ] = -2
		if np.any(pseg>=0):
			# Compress pseg
			cnt = np.bincount( pseg[pseg>=0] )
			k = 0
			for i in range(cnt.size):
				if cnt[i] > 0:
					cnt[i] = k
					k += 1
				else:
					cnt[i] = -1
			pseg[pseg>=0] = cnt[ pseg[pseg>=0] ]
			pseg_to_use.append( pseg )
			over_seg_to_use.append( over_seg )
	# Train the seeds
	print("  * Training  on  %d / %d images"%(len(pseg_to_use),len(psegs)))
	s = proposals.LearnedSeed()
	s.train( over_seg_to_use, pseg_to_use, N_SEED, n_seed_per_obj )

	return s

def evalSeed( seed_functions, N_SEED=[1,3,5,10,25,100,250] ):
	over_segs,segmentations,boxes,names = loadVOCAndOverSeg( "test", detector='mssf', year="2012" )
	from time import time

	n_seg, n_spix, n_seed, n_prod, tme = 0, 0, np.zeros( ( len(seed_functions), len(N_SEED) ) ), np.zeros( ( len(seed_functions), len(N_SEED) ) ), np.zeros(len(N_SEED))
	for id,(ios,seg) in enumerate(zip( over_segs, segmentations )):
		# Count the total number of segments
		pseg = ios.projectSegmentation( seg+1 )-1
		nseg = np.max(seg)+1
		sp_seg = np.unique(pseg[pseg>=0])
		nseg_in_sp = sp_seg.shape[0]
		
		for i,sf in enumerate( seed_functions ):
			recomp = isinstance( sf, proposals.RegularSeed)
			MS = int(np.max(N_SEED))
			if not recomp:
				tme[i] -= time()
				s = sf.compute( ios, MS )
				tme[i] += time()
			
			for j,n in enumerate( N_SEED ):
				if recomp:
					tme[i] -= time()
					ss = sf.compute( ios, n )
					tme[i] += time()
				else:
					ss = s[:n]
				# Find and count all the hit segments
				seed_seg = pseg[ss]
				seed_seg = np.unique(seed_seg[seed_seg>=0])
				nseg_in_seed = seed_seg.shape[0]
				
				# Update the count
				n_seed[i,j] += nseg_in_seed
				n_prod[i,j] += np.unique(ss).shape[0]

		# Update the other counts
		n_spix += nseg_in_sp
		n_seg += nseg

	print( "#SP Seed      %d / %d [%f]"%(n_spix, n_seg, 100*n_spix/n_seg) )
	print( "-"*60 )
	print( ' '*40, "".join( ["     %5d     "%n for n in N_SEED] ) )
	for i,sf in enumerate( seed_functions ):
		print( "%-40s   %s      %d  [t = %0.3fs]"%(str(type(sf).__name__),"    ".join( ["%4d [%3.1f]"%(n, 100*n/n_seg) for n in n_seed[i]] ), n_prod[i,-1], tme[i] / len(segmentations) ) )

def trainAllSeedFunctions():
	from os import path
	# Train various seed function
	if not path.exists( '../data/seed_large.dat' ):
		s = trainSeed(min_size=0.08)
		s.save( '../data/seed_large.dat' )
	if not path.exists( '../data/seed_medium.dat' ):
		s = trainSeed(min_size=0.008,max_size=0.125)
		s.save( '../data/seed_medium.dat' )
	if not path.exists( '../data/seed_small.dat' ):
		s = trainSeed(max_size=0.0125,shrink=1)
		s.save( '../data/seed_small.dat' )
	if not path.exists( '../data/seed_all.dat' ):
		s = trainSeed()
		s.save( '../data/seed_all.dat' )

def main( argv ):
	trainAllSeedFunctions()
	
	# Evaluate various seed function
	seed_functions = [proposals.LearnedSeed('../data/seed_all.dat'),proposals.LearnedSeed('../data/seed_large.dat'),proposals.LearnedSeed('../data/seed_medium.dat'),proposals.LearnedSeed('../data/seed_small.dat'),proposals.GeodesicSeed(),proposals.RegularSeed(),proposals.RandomSeed()]
	evalSeed( seed_functions )

if __name__ == "__main__":
	from sys import argv
	r = main( argv )
	exit( r )
