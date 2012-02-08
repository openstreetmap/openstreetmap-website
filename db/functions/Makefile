QTDIR=../../lib/quad_tile

OS=$(shell uname -s)
ifeq (${OS},Darwin)
    LDFLAGS=-bundle
else
    LDFLAGS=-shared
endif

all: libpgosm.so

clean:
	$(RM) *.so *.o

libpgosm.so: quadtile-pgsql.o maptile-pgsql.o xid_to_int4-pgsql.o
	cc ${LDFLAGS} -o libpgosm.so quadtile-pgsql.o maptile-pgsql.o xid_to_int4-pgsql.o

quadtile-pgsql.o: quadtile.c ${QTDIR}/quad_tile.h
	cc -I `pg_config --includedir` -I `pg_config --includedir-server` -I${QTDIR} -fPIC -O3 -DUSE_PGSQL -c -o quadtile-pgsql.o quadtile.c

maptile-pgsql.o: maptile.c
	cc -I `pg_config --includedir` -I `pg_config --includedir-server` -fPIC -O3 -DUSE_PGSQL -c -o maptile-pgsql.o maptile.c

xid_to_int4-pgsql.o: xid_to_int4.c
	cc -I `pg_config --includedir` -I `pg_config --includedir-server` -fPIC -O3 -DUSE_PGSQL -c -o xid_to_int4-pgsql.o xid_to_int4.c
