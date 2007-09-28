QTDIR=../../lib/quad_tile

libquadtile.so: quadtile.o
	cc -shared -o libquadtile.so quadtile.o

libquadtile.dylib: quadtile.o
	libtool -dynamic quadtile.o -o libquadtile.dylib

quadtile.o: quadtile.c ${QTDIR}/quad_tile.h
	cc `mysql_config --include` -I${QTDIR} -fPIC -O3 -c -o quadtile.o quadtile.c
