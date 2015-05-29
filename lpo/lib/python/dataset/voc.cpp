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
#include "voc.h"
#include "imgproc/image.h"
#include "apng.h"
#include <string>
#include <fstream>
#include <unordered_map>
#include <rapidxml.hpp>

#define XSTR( x ) STR( x )
#define STR( x ) std::string( #x )
#ifdef VOC_DIR
std::string voc_dir = XSTR(VOC_DIR);
#else
std::string voc_dir = ".";
#endif
const std::string VOC_IMAGES = "/JPEGImages/%s.jpg";
const std::string VOC_CLASS = "/SegmentationClass/%s.png";
const std::string VOC_OBJECT = "/SegmentationObject/%s.png";
const std::string VOC_ANNOT = "/Annotations/%s.xml";

RMatrixXs cleanVOC( const RMatrixXus& lbl ) {
	unsigned short * plbl = (unsigned short *)lbl.data();
	RMatrixXs r( lbl.rows(), lbl.cols() );
	short * pr = (short *)r.data();
	for( int i=0; i<lbl.cols()*lbl.rows(); i++ )
		pr[i] = (plbl[i]>250)?-2:(short)plbl[i]-1;
	return r;
}
static std::tuple<RMatrixXi,std::vector<std::string> > readBoxes( const std::string & annot, bool difficult ) {
	
	using namespace rapidxml;
	xml_document<> doc;    // character type defaults to char
	std::ifstream t(annot);
	std::string xml_str = std::string(std::istreambuf_iterator<char>(t),std::istreambuf_iterator<char>());
	doc.parse<0>( (char*)xml_str.c_str() );
	
	xml_node<> *annotation = doc.first_node("annotation");
	std::vector<Vector4i> boxes;
	std::vector<std::string> names;
	for( xml_node<> *objects = annotation->first_node(); objects; objects = objects->next_sibling() ) 
		if( objects->name() == std::string("object") ){
			names.push_back( std::string( objects->first_node("name")->value() ) );
			xml_node<> * bbox = objects->first_node("bndbox");
			if( !(bool)std::stoi( std::string( objects->first_node("difficult")->value() ) ) || difficult )
				boxes.push_back( Vector4i( std::stoi( bbox->first_node("xmin")->value() ),
				                           std::stoi( bbox->first_node("ymin")->value() ),
				                           std::stoi( bbox->first_node("xmax")->value() ),
				                           std::stoi( bbox->first_node("ymax")->value() ) ) );
		}
	RMatrixXi r( boxes.size(), 4 );
	for( int i=0; i<boxes.size(); i++ )
		r.row(i) = boxes[i].transpose();
	return std::make_tuple(r,names);
}
template<int YEAR>
static dict loadEntry( const std::string & name, bool load_seg = true, bool load_im = true, bool difficult=false ) {
	const std::string base_dir = voc_dir + "/VOC" + std::to_string(YEAR) + "/";
	dict r;
	char buf[1024];
	if( load_seg ) {
		sprintf( buf, (base_dir+VOC_OBJECT).c_str(), name.c_str() );
		RMatrixXus olbl = readIPNG16( buf );
		if( !olbl.diagonalSize() )
			return dict();
		r["segmentation"] = cleanVOC(olbl);
		
		sprintf( buf, (base_dir+VOC_CLASS).c_str(), name.c_str() );
		RMatrixXus clbl = readIPNG16( buf );
		if( !clbl.diagonalSize() )
			return dict();
		r["class"] = cleanVOC(clbl);
	}
	if (load_im) {
		sprintf( buf, (base_dir+VOC_IMAGES).c_str(), name.c_str() );
		std::shared_ptr<Image8u> im = imreadShared( buf );
		if( !im || im->empty() )
			return dict();
		r["image"] = im;
	}
	sprintf( buf, (base_dir+VOC_ANNOT).c_str(), name.c_str() );
	auto boxes = readBoxes( buf, difficult );
	r["boxes"] = std::get<0>(boxes);
	r["box_classes"] = std::get<1>(boxes);
	
	r["name"] = name;
	return r;
}
template<int YEAR,bool detect> struct VOC_INFO {
};
template<int YEAR> struct VOC_INFO<YEAR,true> {
	static std::string image_sets[3];
};
template<int YEAR> struct VOC_INFO<YEAR,false> {
	static std::string image_sets[3];
};
template<int YEAR> std::string VOC_INFO<YEAR,true>::image_sets[3] = {"ImageSets/Main/train.txt","","ImageSets/Main/val.txt"};
template<int YEAR> std::string VOC_INFO<YEAR,false>::image_sets[3] = {"ImageSets/Segmentation/train.txt","","ImageSets/Segmentation/val.txt"};

template<int YEAR,bool detect,bool difficult>
list loadVOC( bool train, bool valid, bool test ) {
	const std::string base_dir = voc_dir + "/VOC" + std::to_string(YEAR) + "/";
	bool read[3]={train,valid,test};
	list r;
	for( int i=0; i<3; i++ ) 
		if( read[i] ){
			std::ifstream is(base_dir+VOC_INFO<YEAR,detect>::image_sets[i]);
			if (!is.is_open()) {
				printf("File '%s' not found! Check if DATA_DIR is set properly.\n",(base_dir+VOC_INFO<YEAR,detect>::image_sets[i]).c_str());
				throw std::invalid_argument("Failed to load dataset");
			}
			while(is.is_open() && !is.eof()) {
				std::string l;
				std::getline(is,l);
				if( !l.empty() ) {
					dict d = loadEntry<YEAR>( l, !detect, true, difficult );
					if( len( d ) )
						r.append( d );
					else
						printf("Failed to load image '%s'!\n",l.c_str());
				}
			}
		}
	return r;
}
#define INST_YEAR(N) \
template list loadVOC<N,true ,true >( bool, bool, bool );\
template list loadVOC<N,true ,false>( bool, bool, bool );\
template list loadVOC<N,false,true >( bool, bool, bool );\
template list loadVOC<N,false,false>( bool, bool, bool );
INST_YEAR(2012)
INST_YEAR(2010)
INST_YEAR(2007)
