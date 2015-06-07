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

from lpo import *
from util import *
import numpy as np
from sys import argv,stdout
from os import path
import argparse

parser = argparse.ArgumentParser(description='Train and/or evaluate a proposal model.')
parser.add_argument('filename', type=str, nargs='?',
                   help='model filename')
parser.add_argument('-b', dest='box', action='store_true',
                   help='Train for / Evaluate the bounding box performance')
parser.add_argument('-t', dest='train', action='store_true',
                   help='Force the model training (even if the modelfile exists)')
parser.add_argument('-f0', dest='f0', type=float, default=0.1,
                   help='Model weight for facility location')
parser.add_argument('-d', dest='dataset', type=str, default='VOC',
                   help='The dataset to train and evaluate on (VOC, VOCall or COCO)')
parser.add_argument('-N', dest='N', type=int, default=-1,
                   help='Maximal number of training images')
parser.add_argument('-iou', type=float, default=0.9,
                   help='Max IoU threshold for duplicate removal')
parser.add_argument('-s', type=str, help='Save the best overlap and pool_s in a .npy file')

args = parser.parse_args()
save_name = args.filename
f0 = args.f0

def evaluate( prop, over_segs, segmentations, name='', bos=None, pool_ss=None, max_iou=0.9 ):
	if bos == None: bos = []
	if pool_ss == None: pool_ss = []
	for i in range(0,len(over_segs),100):
		props = prop.propose( over_segs[i:i+100], max_iou )
		bo,pool_s = dataset.evaluateSegmentProposals( props, segmentations[i:i+100] )
		bos.append( bo )
		pool_ss.append( pool_s )
		bo,pool_s = np.vstack( bos ),np.hstack( pool_ss )
		stdout.write('#prop = %0.3f  ABO = %0.3f\r'%(np.mean(pool_s),np.mean(bo[:,0])))
	if len(pool_ss):
		bo,pool_s = np.vstack( bos ),np.hstack( pool_ss )
		print( "LPO %05s & %d & %0.3f & %0.3f & %0.3f & %0.3f &  \\\\"%(name,np.mean(pool_s),np.mean(bo[:,0]),np.sum(bo[:,0]*bo[:,1])/np.sum(bo[:,1]), np.mean(bo[:,0]>=0.5), np.mean(bo[:,0]>=0.7) ) )
	return bos, pool_ss

def evaluateBox( prop, over_segs, boxes, name='', bos=None, pool_ss=None, max_iou=0.9 ):
	if bos == None: bos = []
	if pool_ss == None: pool_ss = []
	for i in range(0,len(over_segs),100):
		props = prop.propose( over_segs[i:i+100], max_iou, True )
		bo,pool_s = dataset.evaluateBoxProposals( props, boxes[i:i+100] )
		bos.append( bo )
		pool_ss.append( pool_s )
		bo,pool_s = np.hstack( bos ),np.hstack( pool_ss )
		stdout.write('#prop = %0.3f  ABO = %0.3f  ARec = %0.3f\r'%(np.nanmean(pool_s),np.mean(bo),np.mean(2*np.maximum(bo-0.5,0))))
	print( "LPO %05s & %d & %0.3f & %0.3f & %0.3f & %0.3f & %0.3f \\\\"%(name,np.nanmean(pool_s),np.mean(bo),np.mean(bo>=0.5), np.mean(bo>=0.7), np.mean(bo>=0.9), np.mean(2*np.maximum(bo-0.5,0)) ) )
	return bos, pool_ss

if save_name == None or not path.exists( save_name ) or args.train:
	if args.dataset[:3].lower() == 'voc':
		if args.dataset[:10].lower() == 'voc_detect':
			over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'train', detector='mssf', year='2012_%s'%args.dataset[4:] )
		else:
			over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'train', detector='mssf' )
		
		if args.dataset.lower() == 'vocall':
			o2,s2,_,_ = loadVOCAndOverSeg( 'test', detector='mssf' )
			over_segs.extend( o2 )
			segmentations.extend( s2 )
			del o2
			del s2
	elif args.dataset.lower() == 'coco':
		over_segs,segmentations,boxes,names = loadCOCOAndOverSeg( 'train', detector='mssf' )
		
	N = args.N
	if N>0:
		over_segs,segmentations,boxes = over_segs[:N], segmentations[:N],boxes[:N]

	print( "Setting up the model" )
	prop = proposals.LPO()
	prop.addGlobal()
	prop.addSeed( proposals.LearnedSeed('../data/seed_large.dat'), 200 )
	prop.addSeed( proposals.LearnedSeed('../data/seed_medium.dat'), 200 )
	prop.addSeed( proposals.LearnedSeed('../data/seed_small.dat'), 250 )
	prop.addGBS("lab",[50,100,150,200,350,600],1000)
	prop.addGBS("hsv",[50,100,150,200,350,600],1000)

	print( "Training", f0 )
	stdout.flush()

	if args.box:
		# Compute the boxes for each of the segmentations
		boxes = [proposals.Proposals(s,np.eye(np.max(s)+1).astype(bool)).toBoxes() for s in segmentations]
		prop.train( over_segs, segmentations, boxes, f0 )
	else:
		prop.train( over_segs, segmentations, f0 )

	if save_name != None:
		prop.save(save_name)

	# Evaluate on the training set
	if args.box:
		all_bos,all_pool_ss = evaluateBox( prop, over_segs, boxes, max_iou=args.iou )
	else:
		all_bos,all_pool_ss = evaluate( prop, over_segs, segmentations, max_iou=args.iou )
else:
	prop = proposals.LPO()
	prop.load(save_name)


# Evaluate on the test set
if args.dataset[:3].lower() == 'voc':
	if args.dataset.lower() == 'voc_detect':
		over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf', year='2012_detect' )
	else:
		over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf' )

	print( "Evaluating Pascal test data" )
	stdout.flush()
	if args.box:
		all_bos,all_pool_ss = evaluateBox( prop, over_segs, boxes, name='(tst)', max_iou=args.iou )
	else:
		all_bos,all_pool_ss = evaluate( prop, over_segs, segmentations, name='(tst)', max_iou=args.iou )
elif args.dataset.lower() == 'coco':
	print( "Loading and evaluating Coco test data" )
	stdout.flush()
	all_bos,all_pool_ss = [],[]
	for n in range(dataset.cocoNFolds()):
		over_segs,segmentations,boxes,names = loadCOCOAndOverSeg( 'test', detector='mssf', fold=n )
		all_bos,all_pool_ss = evaluate( prop, over_segs, segmentations, name='(tst)', bos=all_bos, pool_ss=all_pool_ss, max_iou=args.iou )

if args.s:
	bo,pool_s = np.vstack( all_bos ),np.hstack( all_pool_ss )
	np.save(args.s,(bo,pool_s))
