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
#include "berkeley.h"
#include "apng.h"
#include "imgproc/image.h"
#include <dirent.h>
#include <fstream>
#include <sys/stat.h>

#define XSTR( x ) STR( x )
#define STR( x ) std::string( #x )
#ifdef BERKELEY_DIR
std::string berkeley_dir = XSTR(BERKELEY_DIR);
#else
std::string berkeley_dir = "data/berkeley";
#endif

static std::vector< std::string > listDir(const std::string &dirname) {
	std::vector< std::string > r;
	DIR* dp = opendir( dirname.c_str() );
	if(dp)
		for( dirent * d = readdir( dp ); d != NULL; d = readdir( dp ) )
			r.push_back( d->d_name );
	return r;
}
static int mkdir( const std::string & pathname ){ 
	return mkdir( pathname.c_str(), 0777 );
}

#ifdef HAS_MATIO
#include <matio.h>
static std::tuple< std::vector<RMatrixXs>, std::vector<RMatrixXb> > readMat( const std::string & name ) {
	std::vector<RMatrixXs> seg;
	std::vector<RMatriXb> bnd;
	mat_t * mat = Mat_Open(name.c_str(),MAT_ACC_RDONLY);
	if(mat)
	{
		matvar_t * gt = Mat_VarRead( mat, (char*)"groundTruth" );
		if(!gt)
			return std::make_tuple(seg,bnd);
		int nSeg = gt->dims[1];
		if(!nSeg)
			return std::make_tuple(seg,bnd);
		for( int s = 0; s < nSeg; s++ ) {
			const char * names[2] = {"Segmentation","Boundaries"};
			const int types[2] = {MAT_T_UINT16,MAT_T_UINT8};
			for( int it=0; it<2; it++ ) {
				matvar_t * cl = Mat_VarGetCell(gt, s);
				matvar_t * arr = Mat_VarGetStructField( cl, (void*)names[it], MAT_BY_NAME, 0 );
				int W = arr->dims[1], H = arr->dims[0];
				if( arr->data_type != types[it] )
					printf("Unexpected %s type! Continuing in denial ...\n",names[it]);
				
				if(it==0)
					seg.push_back( MatrixXus::Map((const uint16_t*)arr->data,H,W)-1 );
				else
					bnd.push_back( RMatrixXb::Map((const bool*)arr->data,H,W) );
			}
		}
		Mat_VarFree( gt );
		Mat_Close(mat);
	}
	return std::make_tuple(seg,bnd);
}
#else
static std::tuple< std::vector<RMatrixXs>, std::vector<RMatrixXb> > readMat( const std::string & name ) {
	throw std::invalid_argument( "You need libmatio to read the berkeley segmentation benchmark!\n");
	return std::tuple< std::vector<RMatrixXs>, std::vector<RMatrixXb> >();
}
#endif

static dict loadEntry( std::string name ) {
	std::string sets[] = {"train","val","test"};
	std::string im_dir = berkeley_dir+"/images/";
	std::string gt_dir = berkeley_dir+"/groundTruth/";
	std::string cs_dir = berkeley_dir+"/cache/";
	mkdir( cs_dir );
	for (std::string s: sets)
		mkdir( cs_dir+s );
	
	dict r;
	for (std::string s: sets) {
		std::string im_name = s+"/"+name+".jpg";
		std::shared_ptr<Image8u> im = imreadShared( im_dir + "/" + im_name );
		if( im && !im->empty() ) {
			std::string sname = s+"/"+name+".png", bname = s+"/"+name+"_bnd.png", mname = s+"/"+name+".mat";
			
			std::vector<RMatrixXs> seg;
			{
				std::vector<RMatrixXu8> tmp = readAPNG( cs_dir + "/" + sname );
				for( auto i: tmp )
					seg.push_back( i.cast<short>() );
			}
			std::vector<RMatrixXb> bnd;
			{
				std::vector<RMatrixXu8> tmp = readAPNG( cs_dir + "/" + bname );
				for( auto i: tmp )
					bnd.push_back( i.cast<bool>() );
			}
			
			if( seg.size()==0 || bnd.size()==0 ) {
				std::tie(seg,bnd) = readMat( gt_dir + "/" + mname );
				{
					std::vector<RMatrixXu8> tmp;
					for( auto i: seg )
						tmp.push_back( i.cast<uint8_t>() );
					writeAPNG( cs_dir + "/" + sname, tmp );
				}
				{
					std::vector<RMatrixXu8> tmp;
					for( auto i: bnd )
						tmp.push_back( i.cast<uint8_t>() );
					writeAPNG( cs_dir + "/" + bname, tmp );
				}
			}
			if( bnd.size() && seg.size() ) {
				std::vector<RMatrixXb> bnd_b;
				for( auto i: bnd )
					bnd_b.push_back( i.cast<bool>() );
				r["image"] = im;
				r["segmentation"] = seg;
				r["boundary"] = bnd_b;
				r["name"] = name;
				return r;
			}
		}
	}
	return r;
}
static void loadBSD300( list & r, const std::string & type ) {
	std::string sets[] = {"train","val","test"};
	std::string cs_dir = berkeley_dir+"/cache/";
	std::ifstream is(berkeley_dir+"/bsd300_iids_"+type+".txt");
	mkdir( cs_dir );
	for (std::string s: sets)
		mkdir( cs_dir+s );
	
	while(is.is_open() && !is.eof()) {
		std::string l;
		std::getline(is,l);
		if( !l.empty() ) {
			dict d = loadEntry( l );
			if( len( d ) )
				r.append( d );
		}
	}
}
list loadBSD300( bool train, bool valid, bool test ) {
	list r;
	if( train )
		loadBSD300( r, "train");
	if( test )
		loadBSD300( r, "test");
	return r;
}
static void loadBSD500( list & r, const std::string & type, int max_entry=1<<30 ) {
	std::string sets[] = {"train","val","test"};
	std::string cs_dir = berkeley_dir+"/cache/";
	std::string im_dir = berkeley_dir+"/images/"+type+"/";
	
	mkdir( cs_dir );
	for (std::string s: sets)
		mkdir( cs_dir+s );
	
	std::vector<std::string> files = listDir( im_dir );
	std::sort( files.begin(), files.end() );
	int n = 0;
	for( std::string fn: files )
		if( fn.size() > 4 && fn.substr(fn.size()-4)==".jpg" ) {
			dict d = loadEntry( fn.substr(0,fn.size()-4) );
			if( len( d ) ) {
				r.append( d );
				n++;
				if( n >= max_entry )
					break;
			}
		}
}
list loadBSD500( bool train, bool valid, bool test ) {
	list r;
	if( train )
		loadBSD500( r, "train");
	if( valid )
		loadBSD500( r, "val");
	if( test )
		loadBSD500( r, "test");
	return r;
}
list loadBSD50( bool train, bool valid, bool test ) {
	list r;
	if( train )
		loadBSD500( r, (std::string)"train", 20);
	if( valid )
		loadBSD500( r, (std::string)"val", 10);
	if( test )
		loadBSD500( r, (std::string)"test", 20);
	return r;
}

