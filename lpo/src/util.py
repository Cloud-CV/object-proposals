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

from sys import stdout

try:
	import lz4, pickle
	decompress = lambda s: pickle.loads( lz4.decompress( s ) )
	compress = lambda o: lz4.compressHC( pickle.dumps( o ) )
except:
	compress = lambda x: x
	decompress = lambda x: x

def getDetector( detector="sf" ):
	from lpo import contour
	from os import path
	basedir = path.dirname( path.dirname( path.abspath(__file__) ) )
	if detector=='sf':
		r = contour.StructuredForest()
		r.load( path.join(basedir,'data','sf.dat') )
	elif detector == "mssf":
		r = contour.MultiScaleStructuredForest()
		r.load( path.join(basedir,'data','sf.dat') )
	else:
		r = contour.DirectedSobel()
	return r

def loadAndOverSegDataset( loader, name, detector_name="sf", N_SPIX=1000 ):
	import numpy as np
	from pickle import dumps,loads
	from lpo import segmentation
	from tempfile import gettempdir
	FILE_NAME = '/%s/%s_%s_%d.dat'%(gettempdir(),name,detector_name,N_SPIX)
	try:
		with open(FILE_NAME,'rb') as f:
			print("Loading cache data from", FILE_NAME)
			over_segs,segmentations,boxes,names = loads( f.read() )
			f.close()
			over_seg = segmentation.VecImageOverSegmentation()
			for i in over_segs:
				over_seg.append( decompress(i) )
			return over_seg,[decompress(i) for i in segmentations],[decompress(i) for i in boxes],names
	except IOError:
		pass
	
	# Load the dataset
	data = loader()
	names = [e['name'] for e in data]
	images = [e['image'] for e in data]
	try:
		segmentations = [e['segmentation'] for e in data]
	except:
		segmentations = []
	boxes = [e['boxes'] for e in data if 'boxes' in e]
	
	# Do the over-segmentation
	detector = getDetector(detector=detector_name)

	if detector != None:
		over_segs = segmentation.generateGeodesicKMeans( detector, images, N_SPIX )

	del data # we free the memory used by the images

	print("Saving oversegmentation in", FILE_NAME,
		  "(this might take a while)", end="...")
	stdout.flush()
	with open(FILE_NAME,'wb') as f:
		# this section will require lots of memory
		f.write( dumps( ([compress(i) for i in over_segs],
						 [compress(i) for i in segmentations],
						 [compress(i) for i in boxes], names) ) )
		f.close()
	print("done.")
	return over_segs,segmentations,boxes,names

def loadCOCOAndOverSeg( im_set="test", detector="sf", N_SPIX=1000, fold=0 ):
	from lpo import dataset
	return loadAndOverSegDataset( lambda: dataset.loadCOCO2014(im_set=="train",im_set=="test",fold), "COCO_%s_%d"%(im_set,fold), detector_name=detector, N_SPIX=N_SPIX )

def loadVOCAndOverSeg( im_set="test", detector="sf", N_SPIX=1000, year="2012" ):
	from lpo import dataset
	ldr = eval("dataset.loadVOC%s"%year)
	return loadAndOverSegDataset( lambda: ldr(im_set=="train",im_set=="valid",im_set=="test"), "VOC%s_%s"%(year,im_set), detector_name=detector, N_SPIX=N_SPIX )

def saveProposalsHDF5( p, fn ):
	import h5py
	f = h5py.File(fn, "w")
	for i,pp in enumerate(p):
		dset_s = f.create_dataset("seg_%d"%i, pp.s.shape, dtype='i2', compression="gzip", compression_opts=9)
		dset_s[...] = pp.s
		dset_s = f.create_dataset("prop_%d"%i, pp.p.shape, dtype='i1', compression="gzip", compression_opts=9)
		dset_s[...] = pp.p
	f.close()

def saveProposalsHDF5( p, fn, segments=True, boxes=False ):
	import h5py
	f = h5py.File(fn, "w")
	for i,pp in enumerate(p):
		if segments:
			dset_s = f.create_dataset("seg_%d"%i, pp.s.shape, dtype='i2', compression="lzf")
			dset_s[...] = pp.s
			dset_s = f.create_dataset("prop_%d"%i, pp.p.shape, dtype='i1', compression="lzf")
			dset_s[...] = pp.p
		if boxes:
			bx = pp.toBoxes()
			dset_s = f.create_dataset("box_%d"%i, bx.shape, dtype='i2', compression="gzip", compression_opts=9)
			dset_s[...] = bx
	f.close()

