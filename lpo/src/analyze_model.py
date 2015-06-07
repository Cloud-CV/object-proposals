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

from __future__ import print_function

from pylab import *
from lpo import *
from util import *
from sys import argv,stdout
from os import path
import argparse

# This script generates table 2 (model composition) on the paper

parser = argparse.ArgumentParser(description='Analyze the composition of a proposal model.')
parser.add_argument('filename', type=str, help='model filename')
parser.add_argument('-d', dest='dataset', type=str, default='VOC',
                   help='The dataset to train and evaluate on (VOC, VOCall or COCO)')
parser.add_argument('-N', dest='N', type=int, default=-1,
                   help='Maximal number of trainig images')

args = parser.parse_args()

def evaluateDetailed( prop, over_segs, segmentations ):

	print("Launching detailed evaluation, this might take a while...")
	stdout.flush()

	from time import time
	BS = 100
	names = prop.modelTypes
	r = []
	t = [0]*prop.nModels
	ma = [[] for m in range(prop.nModels)]
	ps = [[] for m in range(prop.nModels)]
	bo = [[] for m in range(prop.nModels)]
	
	for i in range(0,len(over_segs),BS):
		for m in range(prop.nModels):
			t[m] -= time()
			props = prop.propose( over_segs[i:i+BS], 1, m )
			t[m] += time()
			b,pool_s = dataset.evaluateSegmentProposals( props, segmentations[i:i+BS] )
			
			ma[m].extend( [np.median( np.vstack([props[0][0].p.dot( np.bincount(props[0][0].s.flatten()) ) for p in pp]) ) for pp in props] )
			ps[m].extend( pool_s )
			bo[m].extend( list(b[:,0]) )
	bo = [np.array(b) for b in bo]
	bbo = np.max(bo,axis=0)
	
	# Let's print out combined results
	nc = {n:np.sum([n==nn for nn in names]) for n in set(names)}
	nm = {}
	for n in set(names):
		if nc[n] > 1:
			nm[n] = len(ma)
			ma.append(0*np.array(ma[0]))
			ps.append(0*np.array(ps[0]))
			bo.append(0*np.array(bo[0]))
			t.append(0)
			names.append(n+' (cmb)')
	for m in range(prop.nModels):
		if names[m] in nm:
			ma[nm[names[m]]] += np.array(ma[m])*np.array(ps[m])
			ps[nm[names[m]]] += np.array(ps[m])
			bo[nm[names[m]]] = np.maximum( np.array(bo[m]), bo[nm[names[m]]] )
			t[nm[names[m]]]  += t[m]
	for n in set(names):
		if n in nm:
			ma[nm[n]] /= ps[nm[n]]
	ma.append(0*np.array(ma[0]))
	ps.append(0*np.array(ps[0]))
	bo.append(0*np.array(bo[0]))
	t.append(0)
	names.append('all')
	for m in range(prop.nModels):
		ma[-1] += np.array(ma[m])*np.array(ps[m])
		ps[-1] += np.array(ps[m])
		bo[-1] = np.maximum( np.array(bo[m]), bo[-1] )
		t[-1] += t[m]
	ma[-1] /= ps[-1]

	print( "name & pool size & % best & sqrt(median area) & time (see table 2 of paper)")
	for m,n in enumerate(names):
		assert len(ma[m]) > 0
		print( names[m], '&', np.mean(ps[m]), '&', np.mean(bo[m]>=bbo)*100, '&', np.sqrt(np.mean(ma[m])), '&', t[m]/len(ma[m]) )
	


prop = proposals.LPO()
prop.load(args.filename)


# Evaluate on the test set
if args.dataset[:3].lower() == 'voc':
	if args.dataset.lower() == 'voc_detect':
		over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf', year='2012_detect' )
	else:
		over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf' )
	evaluateDetailed( prop, over_segs, segmentations )
elif args.dataset.lower() == 'coco':
	print( "Analysis on COCO is not supported!" )
