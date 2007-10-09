QTDIR=../../lib/quad_tile

OS=$(shell uname -s)
ifeq (${OS},Darwin)
    LDFLAGS=-bundle
else
    LDFLAGS=-shared
endif

libmyosm.so: quadtile.o maptile.o
	cc ${LDFLAGS} -o libmyosm.so quadtile.o maptile.o

quadtile.o: quadtile.c ${QTDIR}/quad_tile.h
	cc `mysql_config --include` -I${QTDIR} -fPIC -O3 -c -o quadtile.o quadtile.c

maptile.o: maptile.c
	cc `mysql_config --include` -fPIC -O3 -c -o maptile.o maptile.c
