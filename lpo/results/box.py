from pylab import *
import numpy as np
from sys import argv
from pickle import load
import argparse

rc('font', size=20)

def createFigAx():
	fig = figure(figsize=(5,4))
	ax = fig.add_axes([0.15,0.15,0.8,0.8])
	ax.grid()
	return fig,ax

our_name = "Our approach"
name_map = {"selsearch_small":"Sel. Search","selsearch_large":"Sel. Search","rprim_large":"Randomized Prim","objectness":"Objectness","bing":"BING","gop_base":"GOP","/tmp/gop2":"GOP2","gop_seed":"GOP2","ebox":"Edge Boxes","lop":our_name,"lpo":our_name}
colors = {"Sel. Search":"#204a87","Randomized Prim":"#4e9a06","Objectness":"#f57900","BING":"#edd400","LOP":"#000000",our_name:"#000000","LOP2":"#00a400","LOP3":"#000000","GOP":"#00a400","Edge Boxes":"#a40000"}
zorder = {"Sel. Search":3,"Randomized Prim":2,"Objectness":1,"BING":0,"LOP":10,our_name:10,"LOP2":10,"LOP3":10,"GOP":7,"Edge Boxes":6}
ls = {"Sel. Search":'--',"Randomized Prim":'--',"Objectness":'--',"BING":'--',"LOP":'-',our_name:'-',"LOP2":'-',"LOP3":'-',"GOP":'-',"Edge Boxes":'-'}

def plot_recall_iou( n, bo, t, legend=False ):
	fig = figure(figsize=(5,4))
	ax = fig.add_axes([0.19,0.17,0.8,0.8])
	ax.grid()
	
	for k,l in enumerate(sorted(bo.keys())):
		recall = np.mean( bo[l]>=t, axis=1 )
		nl = np.logspace(0,4,20)
		irecall = np.interp(np.log(nl),np.log(n[l]),recall)
		plot( nl, irecall, 'o-', zorder=zorder[l], label=l, lw=3, c=colors[l], ls=ls[l] )
		
	
	ax.set_xscale('log')
	if legend:
		ax.legend(loc=2,prop={'size':13}).set_zorder(20)
	ax.set_ylabel("Recall")
	ax.set_xlabel("# of boxes")
	ax.set_xlim(10,MAX_WINDOWS)
	#ax.set_ylim(0,1)
	ax.spines['top'].set_color('gray')
	ax.spines['right'].set_color('gray')
	ax.xaxis.set_ticks_position('bottom')
	ax.yaxis.set_ticks_position('left')
	ax.yaxis.set_major_locator(MultipleLocator(0.2))
	return fig

def plot_abo( n, bo, legend=False ):
	fig = figure(figsize=(5,4))
	ax = fig.add_axes([0.19,0.17,0.8,0.8])
	ax.grid()
	
	for k,l in enumerate(sorted(bo.keys())):
		abo = np.mean( bo[l], axis=1 )
		nl = np.logspace(0,4,20)
		iabo = np.interp(np.log(nl),np.log(n[l]),abo)
		plot( nl, iabo, 'o-', zorder=zorder[l], label=l, lw=3, c=colors[l], ls=ls[l] )
	
	ax.set_xscale('log')
	if legend:
		ax.legend(loc=4,prop={'size':13}).set_zorder(20)
	ax.set_ylabel("Average Best Overlap")
	ax.set_xlabel("# of boxes")
	ax.set_xlim(10,MAX_WINDOWS)
	#ax.set_ylim(0,1)
	ax.spines['top'].set_color('gray')
	ax.spines['right'].set_color('gray')
	ax.xaxis.set_ticks_position('bottom')
	ax.yaxis.set_ticks_position('left')
	ax.yaxis.set_major_locator(MultipleLocator(0.2))
	return fig

def plot_arec( n, bo, legend=False ):
	fig = figure(figsize=(5,4))
	ax = fig.add_axes([0.19,0.17,0.8,0.8])
	ax.grid()
	
	for k,l in enumerate(sorted(bo.keys())):
		arec = np.mean( np.maximum(0,2*bo[l]-1), axis=1 )
		nl = np.logspace(0,4,20)
		iabo = np.interp(np.log(nl),np.log(n[l]),arec)
		plot( nl, iabo, 'o-', zorder=zorder[l], label=l, lw=3, c=colors[l], ls=ls[l] )
	
	ax.set_xscale('log')
	if legend:
		ax.legend(loc=2)
	ax.set_ylabel("Average Recall")
	ax.set_xlabel("# of boxes")
	ax.set_xlim(10,MAX_WINDOWS)
	#ax.set_ylim(0,1)
	ax.spines['top'].set_color('gray')
	ax.spines['right'].set_color('gray')
	ax.xaxis.set_ticks_position('bottom')
	ax.yaxis.set_ticks_position('left')
	ax.yaxis.set_major_locator(MultipleLocator(0.2))
	return fig

def plot_recall_n( n, bo, nn, legend=False ):
	fig = figure(figsize=(5,4))
	ax = fig.add_axes([0.19,0.17,0.8,0.8])
	ax.grid()
	
	t = np.linspace(0.5,1,10)
	for k,l in enumerate(sorted(bo.keys())):
		id = np.argmin( np.abs( n[l] - nn ) )
		b = bo[l][id]
		if n[l][id] < nn:
			n1,n2 = n[l][id],n[l][id+1]
			w = (nn-n1)/(n2-n1)
			b = bo[l][id]*(1-w) + bo[l][id+1]*w
		recall = np.mean( b[None,:]>=t[:,None], axis=1 )
		plot( t, recall, 'o-', zorder=zorder[l], label=l, lw=3, c=colors[l], ls=ls[l] )
	
	if legend:
		ax.legend(loc=2)
	ax.set_ylabel("Recall")
	ax.set_xlabel("$\mathcal{J}$")
	ax.set_xlim(0.5,1)
	#ax.set_ylim(0,1)
	ax.spines['top'].set_color('gray')
	ax.spines['right'].set_color('gray')
	ax.xaxis.set_ticks_position('bottom')
	ax.yaxis.set_ticks_position('left')
	ax.yaxis.set_major_locator(MultipleLocator(0.2))
	return fig

def VUS( n, bo ):
	#print( bo.shape )
	#t = np.linspace(0.5,1,100)
	#recall_vol = np.mean( bo[None]>=t[:,None,None], axis=2 )
	#mean_recall = np.mean( recall_vol, axis=0 )
	abo = np.mean( bo, axis=1 )
	mean_recall = np.mean( np.maximum( 2*bo-1, 0 ), axis=1 )
	nn = np.linspace(1,MAX_WINDOWS,1000)
	nl = np.logspace(0,4,1000)
	nl = nl[nl<MAX_WINDOWS]
	#print( n.astype(int) )
	#print( mean_recall )
	return np.mean(np.interp(np.log(nn),np.log(n),mean_recall)), np.mean(np.interp(np.log(nl),np.log(n),mean_recall)), np.mean(np.interp(MAX_WINDOWS,n,abo)), np.mean(np.interp(MAX_WINDOWS,n,mean_recall))


MAX_WINDOWS = 2000

parser = argparse.ArgumentParser(description='Evaluate the bounding box recall.')
parser.add_argument('dat',type=str,nargs='+',help='dat files containing the recall measures')
parser.add_argument('-o',type=str,help='output file (pdf)')
parser.add_argument('-M',type=int,help='maximum number of windows', default=2000)
args = parser.parse_args()

MAX_WINDOWS = args.M
bo={}
n ={}
for p in args.dat:
	name = p.replace('box/','').replace(".dat","").replace(".npz","")
	if name in name_map:
		name = name_map[ name ]
	npz = np.load( p )
	n[name],bo[name] = npz['arr_0'],npz['arr_1']
	npz.close()
	order = np.argsort(n[name])
	n[name] = n[name][order]
	bo[name] = bo[name][order]
	vus = VUS(n[name],bo[name])

print( "VUS                     Linear   Log      ABO      AREC" )
for k in sorted(bo.keys()):
	vus = VUS(n[k],bo[k])
	print( '%20s\t'%k+"  ".join(['%0.5f'%v for v in vus]) )

if args.o!=None:
	from matplotlib.backends.backend_pdf import PdfPages
	pp = PdfPages(args.o)
	#for t in [0.9,0.7,0.5]:
		#pp.savefig( plot_recall_iou( n, bo, t, legend=t>0.8 ) )
	pp.savefig( plot_abo( n, bo, legend=True ) )
	pp.savefig( plot_arec( n, bo ) )
	for nn in [100,500,1000,2000]:
		pp.savefig( plot_recall_n( n, bo, nn ) )
	pp.close()
	show()
