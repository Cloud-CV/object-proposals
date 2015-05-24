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
#include "crfmodel.h"
#include "crf/crf_features.h"
#include "crf/loss.h"
#include "segmentation/segmentation.h"
#include "util/util.h"

// #define FIT_ALL_SEED

static ApproximateJaccardLoss default_training_loss(1.0,0.25);
// static JaccardLoss default_training_loss(1.0);

/* CRF Proposals */
BinaryCRF paramToCRF( const VectorXf & p ) {
	const int n_u = p[0], n_p = p[1];
	eassert( p.size() >= 2+n_u+n_p );
	BinaryCRF r;
	r.setUnary( p.segment(2,n_u) );
	r.setPairwise( p.segment(2+n_u,n_p) );
	return r;
}
VectorXf CRFToParam( const BinaryCRF & crf ) {
	const int n_u = crf.unary().size(), n_p = crf.pairwise().size();
	VectorXf r( 2+n_u+n_p );
	r[0] = n_u; r[1] = n_p;
	r.segment(2,n_u) = crf.unary();
	r.segment(n_u+2,n_p) = crf.pairwise();
	return r;
}


void CRFModel::setParameters(const std::vector<VectorXf>& params) {
	crfs_.resize( params.size() );
	for( int i=0; i<params.size(); i++ )
		crfs_[i] = paramToCRF( params[i] );
}
void CRFModel::load(std::istream& is) {
	crfs_ = loadVector<BinaryCRF>( is );
}
void CRFModel::save(std::ostream& os) const {
	saveVector<BinaryCRF>( os, crfs_ );
}
std::shared_ptr< LPOModelTrainer > CRFModel::makeTrainer(const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< std::vector<Polygons> > & gt) const {
	eassert( ios.size() == gt.size() );
	std::vector< SegmentationOverlap > gt_overlap( ios.size() );
#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ )
		gt_overlap[i] = SegmentationOverlap( ios[i]->s(), gt[i] );
	return makeTrainerFromOverlap( ios, gt_overlap );
}
std::shared_ptr< LPOModelTrainer > CRFModel::makeTrainer(const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector<RMatrixXs> & gt ) const {
	eassert( ios.size() == gt.size() );
	std::vector< SegmentationOverlap > gt_overlap( ios.size() );
#pragma omp parallel for
	for( int i=0; i<ios.size(); i++ )
		gt_overlap[i] = SegmentationOverlap( ios[i]->s(), gt[i] );
	return makeTrainerFromOverlap( ios, gt_overlap );
}
class CRFTrainer: public LPOModelTrainer {
protected:
	// Per image ground truth
	std::vector< SegmentationOverlap > gt_;

	// Sample to image map
	std::vector<int> sample_to_im_id_, sample_to_seg_id_;

	// Training loss
	const TrainingLoss & loss_;
public:
	CRFTrainer( const std::vector< SegmentationOverlap >& gt, const TrainingLoss & loss = default_training_loss ): gt_(gt), loss_(loss) {
		// Max the sample ids to image ids
		int k=0;
		for( int i=0; i<gt.size(); i++ ) {
			int n = gt[i].nObjects();
			if( sample_to_im_id_.size() < k+n ) {
				sample_to_im_id_.resize( 2*(k+n), -1 );
				sample_to_seg_id_.resize( 2*(k+n), -1 );
			}
			for( int j=0; j<n; j++,k++ ){
				sample_to_im_id_[k] = i;
				sample_to_seg_id_[k] = j;
			}
		}
		sample_to_im_id_.resize( k );
		sample_to_seg_id_.resize( k );
	}
};

/* Global CRF Proposals */
class GlobalCRFTrainer: public CRFTrainer {
protected:
	std::vector< std::shared_ptr<StaticBinaryCRFFeatures> > features_;
public:
    GlobalCRFTrainer(const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap >& gt, const TrainingLoss& loss = default_training_loss): CRFTrainer( gt, loss ) {
		features_.resize( ios.size() );
#pragma omp parallel for
		for( int i=0; i<ios.size(); i++ )
			features_[i] = std::make_shared<StaticBinaryCRFFeatures>( *ios[i] );
	}
	// Train a CRF on a single training sample
	virtual VectorXf fit( int sample ) const {
		const int im_id = sample_to_im_id_[sample], seg_id = sample_to_seg_id_[sample];
		// Train the CRF
		BinaryCRF crf;
		crf.train( features_[im_id], gt_[im_id].project(seg_id).cast<short>(), loss_ );
		return CRFToParam( crf );
	}
	// Train a CRF on a few training samples
	virtual VectorXf refit( const VectorXi & samples, const std::vector<VectorXf> & latent_variables, const VectorXf & previous_parameter ) const {
		// Collect the training example
		std::vector< std::shared_ptr<BinaryCRFFeatures> > f;
		std::vector< VectorXs > gt;
		for( int it=0; it<2; it++ ) { // Being paranoid in case there are no non-empty segments
			for( int i=0; i<samples.size(); i++ ) {
				const int s = samples[i];
				const int im_id = sample_to_im_id_[s], seg_id = sample_to_seg_id_[s];
				VectorXb g = gt_[im_id].project(seg_id);
				if( it || g.any() ) {
					f.push_back( features_[im_id] );
					gt.push_back( g.cast<short>() );
				}
			}
			if( gt.size() ) break;
		}
		// Train the CRF
		BinaryCRF crf;
		crf.train( f, gt, loss_ );
		return CRFToParam( crf );
	}
	// Generate proposals using 'parameter's on image im_id. The function returns a set of latent_variables and proposals
	virtual VectorXf proposeAndEvaluate( const VectorXf & parameter, std::vector<VectorXf> & latent_variables ) const {
		const int n_obj = sample_to_seg_id_.size();
		latent_variables.resize( n_obj );
		if(!parameter.size()) return VectorXf::Zero( n_obj );

		// Prepare the CRFs
		BinaryCRF crf = paramToCRF( parameter );

		std::vector<int> seg_start( gt_.size()+1, 0 );
		for( int i=0; i<gt_.size(); i++ )
			seg_start[i+1] = seg_start[i] + gt_[i].nObjects();

		// Propose like there is no tomorrow
		VectorXf r( n_obj );
#pragma omp parallel for
		for( int im_id=0; im_id<gt_.size(); im_id++ ) {
			int n_seg = gt_[ im_id ].nObjects();
			// Generate the proposals
			VectorXb map = crf.map( features_[im_id] ).array()>0.5;
			// Evaluate the proposal
			r.segment( seg_start[im_id], n_seg ) = gt_[im_id].iou( map );
		}
		return r;
	}

	float averageProposalsPerParameter( const VectorXf & parameter ) const {
		/* Strictly speaking this should be 1. Setting it to a higher value penalizes
		 * global models, which in turn prevents overfitting for small proposal sets.
		 * For large proposal sets this has absolutely no impact. */
		return 5;
	}
	std::string name() const {
		return "Global CRF";
	}
};
GlobalCRFModel::GlobalCRFModel() {
}
std::vector<Proposals> GlobalCRFModel::propose(const ImageOverSegmentation& ios) const {
    std::shared_ptr<BinaryCRFFeatures> f = std::make_shared<StaticBinaryCRFFeatures>( ios );
    const int N = crfs_.size();
	RMatrixXb r( N, ios.Ns() );
    for( int i=0; i<N; i++ )
        r.row( i ) = crfs_[i].map( f ).transpose().array()>0.5;
    return std::vector<Proposals>( 1, Proposals( ios.s(), r ) );
}
std::shared_ptr< LPOModelTrainer > GlobalCRFModel::makeTrainerFromOverlap(const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap > & gt) const {
	eassert( ios.size() == gt.size() );
	return std::make_shared<GlobalCRFTrainer>( ios, gt );
}
DEFINE_MODEL(GlobalCRFModel);


/* Seed CRF Proposals */
class SeedCRFTrainer: public CRFTrainer {
protected:
	std::vector< VectorXi > seeds_;
	float avg_seed_;
	std::vector< std::shared_ptr<CachedSeedBinaryCRFFeatures> > features_;
	std::vector< std::shared_ptr<ImageOverSegmentation> > ios_;
public:
    SeedCRFTrainer(const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap >& gt, const std::shared_ptr<SeedFunction> & seed, int max_seed, const TrainingLoss& loss = default_training_loss): CRFTrainer( gt, loss ), ios_(ios) {
    	seeds_.resize( ios.size() );
		features_.resize( ios.size() );
		int n_seed = 0;
#pragma omp parallel for
		for( int i=0; i<ios.size(); i++ ) {
			// Compute the seeds
			VectorXi seeds = seed->compute( *ios[i], max_seed );
#pragma omp atomic
			n_seed += seeds.size();

			// Only keep seeds that are close to/in a ground truth segment
			ArrayXb m( gt[i].Ns() );
			for( int k=0; k<gt[i].nObjects(); k++ )
				m = m || gt[i].project(k).array();
			ArrayXb mm = m;
			// Dilate
			for( int it=0; it<1; it++ )
				for( Edge e: ios[i]->edges() )
					if( m[e.a] || m[e.b] ) mm[e.a] = mm[e.b] = 1;

			// Filter out all seeds in the background
			VectorXi x( seeds.size() );
			for( int j=0; j<seeds.size(); j++ )
				x[j] = mm[ seeds[j] ];
			seeds_[i] = VectorXi( x.sum() );
			for( int j=0,k=0; j<seeds.size(); j++ )
				if( x[j] )
					seeds_[i][k++] = seeds[j];

			// Create the features
			features_[i] = std::make_shared<CachedSeedBinaryCRFFeatures>( *ios[i], seeds_[i] );
		}
		avg_seed_ = 1.f * n_seed / ios.size();
	}
	// Train a CRF on a single training sample
	virtual VectorXf fit( int sample ) const {
		const int im_id = sample_to_im_id_[sample], seg_id = sample_to_seg_id_[sample];

		VectorXs gt = gt_[im_id].project(seg_id).cast<short>();

		std::vector<int> gt_seed;
		for( int it=0; it<5 && gt_seed.size() == 0; it++ ) {
			// See if there is any seed inside the object
			for( int i=0; i<seeds_[im_id].size(); i++ ){
				if (gt[seeds_[im_id][i]]>0)
					gt_seed.push_back( seeds_[im_id][i] );
			}
			if( gt_seed.size() == 0 ){
				VectorXs gt2 = gt;
				// Dilate the object mask
				for( Edge e: ios_[im_id]->edges() )
					if( gt2[e.a] || gt2[e.b] ) gt[e.a] = gt[e.b] = 1;
			}
		}
		if( gt_seed.size() == 0 )
			return VectorXf();

		// Use a random seed inside the object
		VectorXf best_param;
		float best_iou = -1;
		// Try a all possible seeds
#ifdef FIT_ALL_SEED
		for( int s: gt_seed ) {
#else
		const int s = gt_seed[rand()%gt_seed.size()];
		{
#endif
			// Train the CRF
			BinaryCRF crf;
			crf.train( features_[im_id]->get(s), gt, loss_ );
			VectorXb map = crf.map( features_[im_id]->get(s) ).array() > 0.5;

			float iou = gt_[im_id].iou( map )[ seg_id ];
			if( iou > best_iou ) {
				best_iou = iou;
				best_param = CRFToParam( crf );
			}
		}
		return best_param;
	}
	// Train a CRF on a few training samples
	virtual VectorXf refit( const VectorXi & samples, const std::vector<VectorXf> & latent_variables, const VectorXf & previous_parameter ) const {
		// Collect the training example
		std::vector< std::shared_ptr<BinaryCRFFeatures> > f;
		std::vector< VectorXs > gt;
		for( int it=0; it<2; it++ ) { // Being paranoid in case there are no non-empty segments
			for( int i=0; i<samples.size(); i++ ) {
				const int s = samples[i];
				const int im_id = sample_to_im_id_[s], seg_id = sample_to_seg_id_[s];
				VectorXb g = gt_[im_id].project(seg_id);
				if( it || g.any() ) {
					f.push_back( features_[im_id]->get( latent_variables[i][0] ) );
					gt.push_back( g.cast<short>() );
				}
			}
			if( gt.size() ) break;
		}
		// Train the CRF
		BinaryCRF crf;
		crf.train( f, gt, loss_ );
		return CRFToParam( crf );
	}
	// Generate proposals using 'parameter's on image im_id. The function returns a set of latent_variables and proposals
	virtual VectorXf proposeAndEvaluate( const VectorXf & parameter, std::vector<VectorXf> & latent_variables ) const {
		const int n_obj = sample_to_seg_id_.size();
		latent_variables.resize( n_obj );
		if(!parameter.size()) return VectorXf::Zero( n_obj );

		// Prepare the CRFs
		BinaryCRF crf = paramToCRF( parameter );

		std::vector<int> seg_start( gt_.size()+1, 0 );
		for( int i=0; i<gt_.size(); i++ )
			seg_start[i+1] = seg_start[i] + gt_[i].nObjects();

		// Propose like there is no tomorrow
		VectorXf r( n_obj );
#pragma omp parallel for
		for( int im_id=0; im_id<gt_.size(); im_id++ ) {
			int n_seg = gt_[ im_id ].nObjects();
			VectorXf best_iou = -VectorXf::Ones( n_seg );
			VectorXf best_seed = VectorXf::Ones( n_seg )*seeds_[im_id][0];
			for( int i=0; i<seeds_[im_id].size(); i++ ) {
				const int s = seeds_[im_id][i];
				// Generate the proposals
				VectorXb map = crf.map( features_[im_id]->get(s) ).array()>0.5;
				// Evaluate the proposal
				VectorXf iou = gt_[im_id].iou( map );

				for( int k=0; k<n_seg; k++ )
					if( iou[k] > best_iou[k] ) {
						best_iou[k] = iou[k];
						best_seed[k] = s;
					}
			}
			// Store the result
			r.segment( seg_start[im_id], n_seg ) = best_iou;
			for( int k=0; k<n_seg; k++ )
				latent_variables[ seg_start[im_id]+k ] = VectorXf::Ones(1) * best_seed[k];
		}
		return r;
	}

	float averageProposalsPerParameter( const VectorXf & parameter ) const {
		return avg_seed_;
	}
	std::string name() const {
		return "Seed CRF";
	}
};
SeedCRFModel::SeedCRFModel(const std::shared_ptr<SeedFunction> & seed, int max_seed):seed_(seed),max_seed_(max_seed) {
}
std::vector<Proposals> SeedCRFModel::propose(const ImageOverSegmentation& ios) const {
    std::shared_ptr<SeedBinaryCRFFeatures> f = std::make_shared<SeedBinaryCRFFeatures>( ios );
    VectorXi seeds = seed_->compute( ios, max_seed_ );
    const int N = crfs_.size();
	RMatrixXb r( N*seeds.size(), ios.Ns() );
	for( int j=0,k=0; j<seeds.size(); j++ ) {
		f->update( seeds[j] );
	    for( int i=0; i<N; i++, k++ )
    	    r.row( k ) = crfs_[i].map( f ).array().transpose()>0.5;
    }
    return std::vector<Proposals>( 1, Proposals( ios.s(), r ) );
}
void SeedCRFModel::load(std::istream& is) {
	CRFModel::load( is );
    seed_ = loadSeed( is );
    is.read( (char *)&max_seed_, sizeof(max_seed_) );
}
void SeedCRFModel::save(std::ostream& os) const {
	CRFModel::save( os );
    saveSeed( os, seed_ );
    os.write( (char *)&max_seed_, sizeof(max_seed_) );
}
std::shared_ptr< LPOModelTrainer > SeedCRFModel::makeTrainerFromOverlap(const std::vector< std::shared_ptr<ImageOverSegmentation> > & ios, const std::vector< SegmentationOverlap > & gt) const {
	eassert( ios.size() == gt.size() );
	return std::make_shared<SeedCRFTrainer>( ios, gt, seed_, max_seed_ );
}
DEFINE_MODEL(SeedCRFModel);
