QTDIR=../../lib/quad_tile

libquadtile.so: quadtile.c ${QTDIR}/quad_tile.h
	cc `mysql_config --include` -I${QTDIR} -fPIC -O3 -shared -o libquadtile.so quadtile.c
