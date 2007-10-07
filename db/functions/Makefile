QTDIR=../../lib/quad_tile

OS=$(shell uname -s)
ifeq (${OS},Darwin)
    LDFLAGS=-bundle
else
    LDFLAGS=-shared
endif

libquadtile.so: quadtile.o
	cc ${LDFLAGS} -o libquadtile.so quadtile.o

quadtile.o: quadtile.c ${QTDIR}/quad_tile.h
	cc `mysql_config --include` -I${QTDIR} -fPIC -O3 -c -o quadtile.o quadtile.c
