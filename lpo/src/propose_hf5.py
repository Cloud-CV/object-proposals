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
from sys import argv,stdout
from os import path
import argparse

parser = argparse.ArgumentParser(description='Train and/or evaluate a proposal model.')
parser.add_argument('model_name', type=str, help='model filename')
parser.add_argument('save_path', type=str, help='Base path of hf5 files')
parser.add_argument('-b', dest='box', action='store_true',
                   help='Compute bounding boxes')
parser.add_argument('-bb', action='store_true',
                   help='compute both boxes and segmentations')
parser.add_argument('-bo', action='store_true',
                   help='Use box overlap for NMS (instead of region overlap)')
parser.add_argument('-d', dest='dataset', type=str, default='',
                   help='The dataset to train and evaluate on (VOC, VOCall or COCO)')
parser.add_argument('-i', dest='images', type=str, nargs='+',
                   help='A List of images to evaluate')
args = parser.parse_args()

def generate( prop, over_segs, save_names, segments=True, boxes=False, max_iou=0.9, box_overlap=False ):
	BS = 100
	for i in range(0,len(over_segs),BS):
		ii = min(N,i+BS)
		props = prop.propose( over_segs[i:i+BS], max_iou, box_overlap )
		stdout.write('%3.1f%%\r'%(100*ii/len(over_segs)))
		for p,fn in zip( props, save_names[i:i+BS] ):
			saveProposalsHDF5( p, fn, segments, boxes )
	print( "done"+" "*10 )
# Load the ensemble
prop = proposals.LPO()
prop.load(args.model_name)

# Evaluate on the test set
if args.dataset:
	if args.dataset[:3].lower() == 'voc':
		if args.dataset.lower() == 'voc_detect':
			over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf', year='2012_detect' )
		else:
			over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf' )
		save_names = [args.save_path+str(n)+'.hf5' for n in names]
		generate( prop, over_segs, save_names, not args.box or args.bb, args.box or args.bb, box_overlap=args.bo )
	elif args.dataset.lower() == 'coco':
		for n in range(dataset.cocoNFolds()):
			over_segs,segmentations,boxes,names = loadCOCOAndOverSeg( 'train', detector='mssf', fold=n )
			save_names = ["%s%012d.hf5"%(args.save_path,n) for n in names]
			generate( prop, over_segs, save_names, not args.box or args.bb, args.box or args.bb, box_overlap=args.bo )

if args.images:
	from time import time
	detector = getDetector('mssf')
	
	if len(args.images)==1 and not path.exists(args.images[0]):
		from glob import glob
		args.images = glob(args.images[0])
	
	BS,N = 100,len(args.images)
	tl,ts,tp,to = 0,0,0,0
	for i in range(0,N,BS):
		ii = min(N,i+BS)
		# Load the images
		imgs,names = [],[]
		stdout.write('Loading %3.1f%%  [%0.3fs  %0.3fs  %0.3fs  %0.3fs / im]\r'%(100*(ii)/N,tl/(i+1e-3),to/(i+1e-3),tp/(i+1e-3),ts/(i+1e-3)))
		tl -= time()
		for nm in args.images[i:ii]:
			names.append( path.splitext(path.basename(nm))[0] )
			imgs.append( imgproc.imread(nm) )
		tl += time()
		
		stdout.write('Overseg %3.1f%%  [%0.3fs  %0.3fs  %0.3fs  %0.3fs / im]\r'%(100*(ii)/N,tl/ii,to/(i+1e-3),tp/(i+1e-3),ts/(i+1e-3)))
		to -= time()
		over_segs = segmentation.generateGeodesicKMeans( detector, imgs, 1000 )
		to += time()
		
		stdout.write('Propose %3.1f%%  [%0.3fs  %0.3fs  %0.3fs  %0.3fs / im]\r'%(100*(ii)/N,tl/ii,to/ii,tp/(i+1e-3),ts/(i+1e-3)))
		tp -= time()
		props = prop.propose( over_segs )
		tp += time()
		
		stdout.write('Saving  %3.1f%%  [%0.3fs  %0.3fs  %0.3fs  %0.3fs / im]\r'%(100*(ii)/N,tl/ii,to/ii,tp/ii,ts/(i+1e-3)))
		ts -= time()
		for p,n in zip( props, names ):
			saveProposalsHDF5( p, args.save_path+str(n)+'.hf5', not args.box or args.bb, args.box or args.bb )
		ts += time()
	stdout.write('Done    %3.1f%%  [%0.3fs  %0.3fs  %0.3fs  %0.3fs / im]\n'%(100*(ii)/N,tl/ii,to/ii,tp/ii,ts/ii))

