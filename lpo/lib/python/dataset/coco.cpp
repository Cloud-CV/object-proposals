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
#include "coco.h"
#include "imgproc/image.h"
#include "util/util.h"
#include "rapidjson/document.h"
#include <string>
#include <fstream>
#include <random>
#include "util/rasterize.h"

static const int N_FOLDS = 20; // Since not all images fit in memory
static const bool ONLY_CONNECTED = false;
#define XSTR( x ) STR( x )
#define STR( x ) std::string( #x )
#ifdef COCO_DIR
std::string coco_dir = XSTR(COCO_DIR);
#else
std::string coco_dir = ".";
#endif
const std::string COCO_ANNOT = coco_dir+"/instances_%s.json";

// #define DONT_LOAD_IMAGE

list loadCOCO( const std::string & name, int fold ) {
	using namespace rapidjson;
	// Load the annotations
	char buf[1024];
	sprintf( buf, COCO_ANNOT.c_str(), name.c_str() );

	// Read the json file
	Document doc;
	std::ifstream t(buf);
	if (!t.is_open()) {
		printf("File '%s' not found! Check if DATA_DIR is set properly.\n",buf);
		throw std::invalid_argument("Failed to load dataset");
	}
	std::string json_str = std::string(std::istreambuf_iterator<char>(t),std::istreambuf_iterator<char>());

	doc.Parse( (char*)json_str.c_str() );

	// Go through all instance labels
	std::unordered_map< uint64_t, std::vector<int> > categories;
	std::unordered_map< uint64_t, std::vector<float> > areas;
	std::unordered_map< uint64_t, std::vector<Polygons> > segments;
	const Value & instances = doc["annotations"];
	for ( Value::ConstValueIterator i = instances.Begin(); i != instances.End(); i++ ) {
		// Ignore crowds for now
		Value::ConstMemberIterator cmi_iscrowd_id = i->FindMember("iscrowd");
		if( cmi_iscrowd_id != i->MemberEnd() && cmi_iscrowd_id->value.GetInt())
			continue;

		// Get the image id
		Value::ConstMemberIterator cmi_image_id = i->FindMember("image_id");
		eassert( cmi_image_id != i->MemberEnd() );
		const int image_id = cmi_image_id->value.GetInt();

		// Get the category id
		Value::ConstMemberIterator cmi_category_id = i->FindMember("category_id");
		eassert( cmi_category_id != i->MemberEnd() );
		const int category_id = cmi_category_id->value.GetInt();

		// Get the category id
		Value::ConstMemberIterator cmi_area = i->FindMember("area");
		eassert( cmi_area != i->MemberEnd() );
		const float area = cmi_area->value.GetDouble();

		// Read the polygon
		Value::ConstMemberIterator cmi_segmentation = i->FindMember("segmentation");
		eassert( cmi_segmentation != i->MemberEnd() );
		const Value & segmentations = cmi_segmentation->value;

		// For now just use the first segmentation for each object
		Polygons polygons;
		for( Value::ConstValueIterator segmentation = segmentations.Begin(); segmentation!=segmentations.End(); segmentation++ ) {
			Polygon polygon = RMatrixXf( segmentation->Size() / 2, 2 );
			float * ppolygon = polygon.data();
			for ( Value::ConstValueIterator j = segmentation->Begin(); j != segmentation->End(); j++ )
				*(ppolygon++) = j->GetDouble();
			polygons.push_back( polygon );
		}
		if( !ONLY_CONNECTED || polygons.size() == 1 ) {
			categories[ image_id ].push_back( category_id );
			segments[ image_id ].push_back( polygons );
			areas[ image_id ].push_back( area );
		}
	}

	// Load all images
	Value::ConstValueIterator B = doc["images"].Begin(), E = doc["images"].End();
	const int N = E-B;
	std::mt19937 rand(0);
	std::vector<int> ids_in_fold;
	for( int i=0; i<N; i++ )
		if ((rand()%N_FOLDS) == fold)
			ids_in_fold.push_back( i );
	std::sort( ids_in_fold.begin(), ids_in_fold.end() );

#ifndef DONT_LOAD_IMAGE
	std::vector< std::shared_ptr<Image8u> > images( ids_in_fold.size() );
	#pragma omp parallel for
	for ( int k=0; k<ids_in_fold.size(); k++ ) {
		Value::ConstValueIterator i = B+ids_in_fold[k];
		// Get the file name and path
		Value::ConstMemberIterator cmi_file_name = i->FindMember("file_name");
		eassert( cmi_file_name != i->MemberEnd() );
		const std::string file_name = cmi_file_name->value.GetString();

		// Add the image entry
		std::shared_ptr<Image8u> im = imreadShared( coco_dir+"/"+name+"/"+file_name );
		if( im && im->C()==1 )
			im = std::make_shared<Image8u>( im->tileC(3) );
		images[ k ] = im;
	}
#endif
	// Create the python struct with the result
	list r;
	for ( int k=0; k<ids_in_fold.size(); k++ ) {
		Value::ConstValueIterator i = B+ids_in_fold[k];
		// Get the image id
		Value::ConstMemberIterator cmi_image_id = i->FindMember("id");
		eassert( cmi_image_id != i->MemberEnd() );
		const int image_id = cmi_image_id->value.GetInt();

		// Add the image entry
		const int N = categories[ image_id ].size();
		if( N > 0 ) {
			dict entry;
			entry["name"] = image_id;
#ifndef DONT_LOAD_IMAGE
			entry["image"] = images[k];
#endif
			entry["categories"] = categories[ image_id ];
			entry["areas"] = areas[ image_id ];
			entry["segmentation"] = segments[ image_id ];
			r.append( entry );
		}
// 		else
// 			printf("Image '%d' doesn't have any annotations!\n", image_id );
	}

	return r;
}

int cocoNFolds() {
	return N_FOLDS;
}

list loadCOCO2014( bool train, bool valid, int fold ) {
	if( train )
		return loadCOCO( "train2014", fold );
	if( valid )
		return loadCOCO( "val2014", fold );
	return list();
}
