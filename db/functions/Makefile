QTDIR=../../lib/quad_tile

OS=$(shell uname -s)
ifeq (${OS},Darwin)
    LDFLAGS=-bundle
else
    LDFLAGS=-shared
endif

all: libmyosm.so libpgosm.so

clean:
	$(RM) *.so *.o

libmyosm.so: quadtile-mysql.o maptile-mysql.o
	cc ${LDFLAGS} -o libmyosm.so quadtile-mysql.o maptile-mysql.o

libpgosm.so: quadtile-pgsql.o maptile-pgsql.o xid_to_int4-pgsql.o
	cc ${LDFLAGS} -o libpgosm.so quadtile-pgsql.o maptile-pgsql.o xid_to_int4-pgsql.o

quadtile-mysql.o: quadtile.c ${QTDIR}/quad_tile.h
	cc `mysql_config --include` -I${QTDIR} -fPIC -O3 -DUSE_MYSQL -c -o quadtile-mysql.o quadtile.c

quadtile-pgsql.o: quadtile.c ${QTDIR}/quad_tile.h
	cc -I `pg_config --includedir` -I `pg_config --includedir-server` -I${QTDIR} -fPIC -O3 -DUSE_PGSQL -c -o quadtile-pgsql.o quadtile.c

maptile-mysql.o: maptile.c
	cc `mysql_config --include` -fPIC -O3 -DUSE_MYSQL -c -o maptile-mysql.o maptile.c

maptile-pgsql.o: maptile.c
	cc -I `pg_config --includedir` -I `pg_config --includedir-server` -fPIC -O3 -DUSE_PGSQL -c -o maptile-pgsql.o maptile.c

xid_to_int4-pgsql.o: xid_to_int4.c
	cc -I `pg_config --includedir` -I `pg_config --includedir-server` -fPIC -O3 -DUSE_PGSQL -c -o xid_to_int4-pgsql.o xid_to_int4.c
