/*
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
*/
#include "structuredforest.h"
#include "imgproc/color.h"
#include "imgproc/filter.h"
#include "imgproc/nms.h"
#include "imgproc/gradient.h"
#include "imgproc/resample.h"
#include "util/sse_defs.h"
#ifdef __SSE4_1__
#include <smmintrin.h>
#endif
#include <iostream>
#include <fstream>
#include <unordered_map>
#include <cstdio>

void filterOutSmallSegments( RMatrixXs & seg, int min_size=5 ) {
	const int Ns = seg.maxCoeff()+1, W = seg.cols(), H = seg.rows();
	// Filter out small segments
	for( int it=0; it<2; it++ )
		for( int l=0; l<Ns; l++ ) {
			RMatrixXb mask = seg.array() == l;
			if( mask.any() && mask.cast<int>().sum() <= min_size ) {
				VectorXi cnt = VectorXi::Zero(Ns);
				for( int j=0; j<H; j++ )
					for( int i=0; i<W; i++ )
						if( mask(j,i) ) {
							if( i ) cnt[ seg(j,i-1) ]++;
							if( j ) cnt[ seg(j-1,i) ]++;
							if( i<W-1 ) cnt[ seg(j,i+1) ]++;
							if( j<H-1 ) cnt[ seg(j+1,i) ]++;
						}
				cnt[l] = 0;
				// Find the new label
				int new_l;
				float mx = cnt.maxCoeff( &new_l );
				if( new_l == l )
					printf("No new l found!%d %d  %f\n", l, new_l, mx );
				// And update the seg
				seg += (new_l-l)*mask.cast<short>();
			}
		}
	// Compress the seg
	VectorXs remap = -VectorXs::Ones( Ns );
	for( int j=0,k=0; j<H; j++ )
		for( int i=0; i<W; i++ )
			if( remap[ seg(j,i) ] == -1 )
				remap[ seg(j,i) ] = k++;
	for( int j=0; j<H; j++ )
		for( int i=0; i<W; i++ )
			seg(j,i) = remap[ seg(j,i) ];
}

StructuredForestSettings::StructuredForestSettings( int stride, int shrink, int out_patch_size, int feature_patch_size, int patch_smooth, int sim_smooth, int sim_cells ):stride(stride),shrink(shrink),out_patch_size(out_patch_size),feature_patch_size(feature_patch_size),patch_smooth(patch_smooth),sim_smooth(sim_smooth),sim_cells(sim_cells) {
}
StructuredForest::StructuredForest(int nms, int suppress, const StructuredForestSettings & s):nms_(nms),suppress_(suppress),settings_(s) {
}
StructuredForest::StructuredForest(const StructuredForestSettings & s):nms_(1),suppress_(5),settings_(s) {
}
RMatrixXf StructuredForest::detect(const Image8u & rgb_im) const {
	const int Rp = settings_.out_patch_size/2; // Patch radius
	const int pW = rgb_im.W()+2*Rp, pH = rgb_im.H()+2*Rp;

	std::vector<int> os;
	for( int j=0; j<2*Rp; j++ )
		for( int i=0; i<2*Rp; i++ )
			os.push_back( i+j*pW );


	RMatrixXf r = RMatrixXf::Zero( pH, pW );

	SFFeatures f( rgb_im );
	int s = f.x_[1] - f.x_[0];
	float v = 1.5*s*s / (1.0*Rp*Rp*forest_.nTrees()/2);
// 	float v = 0.5*s*s / (1.0*Rp*Rp*forest_.nTrees()/2);
// 	float v = 0.5*s*s / (1.0*Rp*Rp);
	for( int t=0; t<forest_.nTrees(); t++ ) {
		for( int i=0; i<f.id_.size(); i++ ) {
			const int x = f.x_[i], y = f.y_[i];
			if( (((x+y)/s)&1) == (t&1) ) {
				RangeData rng = forest_.tree(t).predictData( f, i );
				float * pr = r.data() + (x + y*pW);
				for( int b=rng.begin; b < rng.end; b++ )
					pr[ os[ patch_ids_[b] ] ] += v;
			}
		}
	}
	RMatrixXf rr = 1*r;
	tentFilter( rr.data(), r.data(), r.cols(), r.rows(), 1, 1 );
	rr.array() = rr.array().min(1.f).sqrt();
	return rr.block( Rp, Rp, rgb_im.H(), rgb_im.W() );
}
RMatrixXf StructuredForest::filter(const RMatrixXf &detection, int suppress, int nms) const {
	if( suppress==-1 ) suppress = suppress_;
	if( nms==-1 ) nms = nms_;

	RMatrixXf r = detection;
	if( nms > 0 )
		r = ::nms( r, nms );
	if(suppress>0)
		suppressBnd( r, suppress );
	return r.array().min(1-1e-10).max(1e-10);
}
RMatrixXf StructuredForest::filter(const RMatrixXf &detection) const {
	return filter( detection, -1, -1 );
}
void StructuredForest::load(const std::string &fn) {
	std::ifstream s( fn, std::ios::in | std::ios::binary );
	if(!s.is_open())
		throw std::invalid_argument( "Could not open file '"+fn+"'!" );
	forest_.load( s );
	// Load patch_ids
	int sz;
	s.read( (char*)&sz, sizeof(sz) );
	patch_ids_ = VectorXus(sz);
	s.read( (char*)patch_ids_.data(), sizeof(unsigned short)*sz );
	s.read( (char*)&settings_, sizeof(settings_) );
}
void StructuredForest::save(const std::string &fn) const {
	std::ofstream s( fn, std::ios::out | std::ios::binary );
	forest_.save( s );
	// Save patch_ids
	int sz = patch_ids_.size();
	s.write( (const char*)&sz, sizeof(sz) );
	s.write( (const char*)patch_ids_.data(), sizeof(unsigned short)*sz );
	s.write( (const char*)&settings_, sizeof(settings_) );
}
void StructuredForest::setFromMatlab(const RMatrixXf &thrs, const RMatrixXi &child, const RMatrixXi &fid, const VectorXi &rng, const VectorXus & patch_ids) {
	forest_ = RangeForest();
	for( int i=0; i<thrs.rows(); i++ ) {
		RangeTree t;
		t.setFromMatlab( thrs.row(i), child.row(i), fid.row(i), rng.segment(i*fid.cols(), fid.cols()+1 ) );
		forest_.addTree( t );
	}
	patch_ids_ = patch_ids;
}
void StructuredForest::fitAndAddTree( const Features & f, const std::vector<RMatrixXs> & lbl, const VectorXi & fid, TreeSettings settings, bool mt ) {
	const int N = f.nSamples();
	eassert( N == lbl.size() );
	const int PS = settings_.out_patch_size;
	const int M = PS*PS;

	// Flatten the paches into labels
	RMatrixXf tree_lbl( N, M );
	for( int i=0; i<N; i++ ) {
		eassert( lbl[i].cols()==settings_.out_patch_size && lbl[i].rows()==settings_.out_patch_size );
		float * pt = tree_lbl.data()+i*M;
		const short * pl = lbl[i].data();
		for( int j=0; j<M; j++ )
			pt[j] = pl[j];
	}

	// Fit the tree (to dummy data)
	RangeTree t;
	std::vector<RangeData> tree_data( N );
	for( int i=0; i<N; i++ )
		tree_data[i].begin = tree_data[i].end = i;

	// Train the tree
	t.fit( f, arange(N), tree_lbl, VectorXf::Ones(N), tree_data, mt, settings );
	// Remap the features ids
	t.remapFid( fid );

	// Create the corresponding data
	std::vector<RMatrixXb> patch_data( N );
	for( int i=0; i<N; i++ ) {
		RMatrixXs seg = lbl[i];
		filterOutSmallSegments( seg, 5 );
		const int H = seg.rows(), W = seg.cols();

		patch_data[i] = RMatrixXb::Zero( H, W );
		RArrayXXb dx = seg.leftCols( W-1 ).array() != seg.rightCols( W-1 ).array();
		RArrayXXb dy = seg.topRows( H-1 ).array() != seg.bottomRows( H-1 ).array();
		patch_data[i].leftCols( W-1 ).array()   = patch_data[i].leftCols( W-1 ).array()   || dx;
		patch_data[i].rightCols( W-1 ).array()  = patch_data[i].rightCols( W-1 ).array()  || dx;
		patch_data[i].topRows( H-1 ).array()    = patch_data[i].topRows( H-1 ).array()    || dy;
		patch_data[i].bottomRows( H-1 ).array() = patch_data[i].bottomRows( H-1 ).array() || dy;
	}

	// Compute the new patch size
	int data_size = 0;
	for( const RangeData & d: t.data() )
		data_size += patch_data[d.begin].cast<int>().sum();

	// Allocate the new patch data
	int o = patch_ids_.size();
	patch_ids_.conservativeResize( o+data_size );

	// Add the new patch data
	for( RangeData & d: t.data() ) {
		VectorXb r = VectorXb::Map( patch_data[d.begin].data(), M );
		d.begin = o;
		// Add a patch
		for( int i=0; i<r.size(); i++ )
			if( r[i] )
				patch_ids_[o++] = i;
		d.end = o;
	}

	forest_.addTree( t );
}
void StructuredForest::compress() {
	VectorXb used = VectorXb::Zero( patch_ids_.size() );
	std::unordered_map< std::string, RangeData > patches;
	// Detect duplicate patches
	for( int t=0; t<forest_.nTrees(); t++ ) {
		std::vector<RangeData> & data = forest_.tree(t).data();
		for( RangeData & d: data )
			if( d.begin<d.end ) {
				VectorXus p = patch_ids_.segment( d.begin, d.end-d.begin );
				std::string hp( (char*)p.data(), sizeof(p[0])*p.size() );
				if( patches.count( hp ) )
					d = patches[ hp ];
				else {
					patches[ hp ] = d;
					used.segment( d.begin, d.end-d.begin ).setOnes();
				}
			}
	}
	// Recompute the patch_ids
	int new_patch_size = used.cast<int>().sum();
	VectorXus new_patch_ids( new_patch_size );
	VectorXi new_id = VectorXi::Zero( patch_ids_.size()+1 );
	for( int i=0,j=0; i<(int)patch_ids_.size(); i++ ) {
		new_id[i] = j;
		if( used[i] ) {
			new_patch_ids[j] = patch_ids_[i];
			j++;
		}
	}
	new_id[ new_id.size()-1 ] = new_patch_size;
	patch_ids_ = new_patch_ids;
	// Remap the ids
	for( int t=0; t<forest_.nTrees(); t++ ) {
		std::vector<RangeData> & data = forest_.tree(t).data();
		for( RangeData & d: data ) {
			d.begin = new_id[ d.begin ];
			d.end = new_id[ d.end ];
		}
	}
}
RMatrixXf MultiScaleStructuredForest::detect( const Image8u & rgb_im ) const {
	RMatrixXf r = RMatrixXf::Zero( rgb_im.H(), rgb_im.W() );
	float scales[] = {0.5,1.0,2.0};
	for( float s: scales ) {
		Image8u im = resize( rgb_im, s*rgb_im.W(), s*rgb_im.H() );
		r += resize( StructuredForest::detect( im ), rgb_im.W(), rgb_im.H() );
	}
	return r.array() / 3.;
}

SFFeatures::SFFeatures(const Image8u & im, const StructuredForestSettings & s) {
	// Define some magic constants
	const int chns_smooth = s.patch_smooth / s.shrink;
	const int sim_smooth =  s.sim_smooth / s.shrink;
	const int R = s.feature_patch_size/2, shrink = s.shrink, stride = s.stride;
	const int Rs = R / s.shrink;
	const int nCells = s.sim_cells;
	const int norm_rad = 4;
	const float norm_const = 0.01;

	/***** Compute the Patch Features *****/
	const int W = im.W(), H = im.H();
	const int pW = W+2*R, pH = H+2*R;
	const int dH = pH/shrink, dW = pW/shrink;
	Image luv;
	rgb2luv( luv, im );
	Image pluv = padIm( luv, R );

	// Downsample
	Image dluv = downsample( pluv, dW, dH );

	/* Create the features */
	const int Nf = 13;
	RMatrixXf features( dH*dW, Nf );

	// Luv color feature
	int o=0;

	features.block( 0, 0, dW*dH, 3 ) = RMatrixXf::Map( dluv.data(), dW*dH, 3 );
	o += 3;

	// Full resulution oriented gradient
	{
		RMatrixXf gm(pH,pW), go(pH,pW);
		gradientMagAndOri( gm, go, pluv, norm_rad, norm_const );

		// Add the gradient magnitude
		RMatrixXf dgm = downsample( gm, dW, dH );
		features.col(o++) = Map<VectorXf>( dgm.data(), dW*dH, 1 );

		// Add the gradient histogram
		Image h;
		gradientHist( h, gm, go, 4, shrink );

		features.block( 0, o, dW*dH, 4 ) = RMatrixXf::Map( h.data(), dW*dH, 4 );
		o += 4;
	}
	// Half resulution oriented gradient
	{
		RMatrixXf gm(dH,dW), go(dH,dW);
		gradientMagAndOri( gm, go, dluv, norm_rad, norm_const );

		// Add the gradient magnitude
		features.col(o++) = Map<VectorXf>( gm.data(), dW*dH, 1 );

		// Add the gradient histogram
		Image h;
		gradientHist( h, gm, go, 4, 1 );

		features.block( 0, o, dW*dH, 4 ) = RMatrixXf::Map( h.data(), dW*dH, 4 );
		o += 4;
	}
	// Blur all features
	patch_features_ = 1*features;
	tentFilter( patch_features_.data(), features.data(), dW, dH, Nf, chns_smooth );

	/***** Compute the ssim features *****/
	ssim_features_ = 1*features;
	tentFilter( ssim_features_.data(), features.data(), dW, dH, Nf, sim_smooth );

	// Patch features offsets
	for( int i=0; i<2*Rs; i++ )
		for( int j=0; j<2*Rs; j++ )
			for( int f=0; f<Nf; f++ )
				did_.push_back( (i+j*dW)*Nf+f );

	// ssim features offsets
	std::vector<int> locs;
	int Rp = (int)(1.0*Rs/nCells+0.5); // Patch radius in px
	for(int i=0; i<nCells; i++)
		locs.push_back( (i+1)*(2*Rs+2*Rp-1)/(nCells+1.0)-Rp+0.5 );
	for( int i1=0,k1=0; i1 < nCells; i1++ )
		for( int j1=0; j1 < nCells; j1++,k1++ )
			for( int i2=0,k2=0; i2 < nCells; i2++ )
				for( int j2=0; j2 < nCells; j2++,k2++ )
					if( k1 < k2 )
						for( int f=0; f<Nf; f++ ) {
							did1_.push_back( (locs[j1]*dW+locs[i1])*Nf+f );
							did2_.push_back( (locs[j2]*dW+locs[i2])*Nf+f );
						}

	n_patch_feature_ = did_.size();
	n_ssim_feature_ = did1_.size();
	n_feature_ = n_patch_feature_ + n_ssim_feature_;

	id_.reserve((dH-2*Rs)*(dW-2*Rs));
	x_ = VectorXi((dH-2*Rs)*(dW-2*Rs));
	y_ = VectorXi((dH-2*Rs)*(dW-2*Rs));
	for (int j=0,k=0; j+2*Rs<dH; j+=stride/shrink)
		for (int i=0; i+2*Rs<dW; i+=stride/shrink,k++) {
			id_.push_back( Nf*(j*dW+i) );
			x_[k] = i*shrink;
			y_[k] = j*shrink;
		}
}
const VectorXi& SFFeatures::x() const {
	return x_;
}
const VectorXi& SFFeatures::y() const {
	return y_;
}
const RMatrixXf& SFFeatures::patchFeatures() const {
	return patch_features_;
}
const RMatrixXf& SFFeatures::ssimFeatures() const {
	return ssim_features_;
}
int SFFeatures::nSamples() const {
	return id_.size();
}
int SFFeatures::featureSize() const {
	return n_feature_;
}
float SFFeatures::get(int s, int f) const {
	return fastget(s,f);
}
