INCDIR = -I.
DBG    = -g
OPT    = -O3
CPP    = g++
CFLAGS = $(DBG) $(OPT) $(INCDIR)
LINK   = -lm -L. -lsegment

#.cpp.o:
#	$(CPP) $(CFLAGS) -c $< -o $@


all: segment

include depfile

segment: segment.cpp libsegment.a depfile
	$(CPP) $(CFLAGS) -o segment segment.cpp $(LINK)


libsegment.a: image.o pnmfile.o segment-image.o misc.o depfile
	ar rcs $@ $^

mex: 
	mex segment_fh_mex.cc -I./ 
clean:
	/bin/rm -f segment *.o

clean-all: clean
	/bin/rm -f *~ 

depfile:
	gcc -MM *.cpp > $@
	

