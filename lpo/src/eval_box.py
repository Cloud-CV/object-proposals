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
from sys import argv,stdout
from pickle import dump
import numpy as np

def evaluateBox( prop, over_segs, boxes, name='', max_iou=0.9 ):
	bos, pool_ss = [],[]
	for i in range(0,len(over_segs),100):
		props = prop.propose( over_segs[i:i+100], max_iou, True ) # Use box_nms
		bo,pool_s = dataset.evaluateBoxProposals( props, boxes[i:i+100] )
		bos.append( bo )
		pool_ss.append( pool_s )
		bo,pool_s = np.hstack( bos ),np.hstack( pool_ss )
		stdout.write('#prop = %0.3f  ABO = %0.3f  ARec = %0.3f\r'%(np.nanmean(pool_s),np.mean(bo),np.mean(2*np.maximum(bo-0.5,0))))
	print( "LPO %05s & %d & %0.3f & %0.3f & %0.3f & %0.3f & %0.3f \\\\"%(name,np.nanmean(pool_s),np.mean(bo),np.mean(bo>=0.5), np.mean(bo>=0.7), np.mean(bo>=0.9), np.mean(2*np.maximum(bo-0.5,0)) ) )
	return bo,pool_s

if len(argv)<3:
	print( "Usage: %s save_file model1 [model2 model3 ...]"%argv[0] )
	exit(1)

# Evaluate on the test set
over_segs,segmentations,boxes,names = loadVOCAndOverSeg( 'test', detector='mssf', year='2012_detect' )

bos, pool_ss = [],[]
for md in argv[2:]:
	prop = proposals.LPO()
	prop.load(md)
	bo,pool_s = evaluateBox( prop, over_segs, boxes, name='(tst)' )
	bos.append( bo )
	pool_ss.append( np.nanmean(pool_s) )
	
	dump( (np.array(pool_ss),np.array(bos)), open(argv[1],'wb') )
