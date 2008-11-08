QTDIR=../../lib/quad_tile

PGSQLINC=/usr/include/postgresql/8.3/server/

OS=$(shell uname -s)
ifeq (${OS},Darwin)
    LDFLAGS=-bundle
else
    LDFLAGS=-shared
endif

all: libmyosm.so libpgosm.so

clean:
	$(RM) *.so *.o

libmyosm.so: quadtile.o maptile-mysql.o
	cc ${LDFLAGS} -o libmyosm.so quadtile.o maptile-mysql.o

libpgosm.so: maptile-pgsql.o
	cc ${LDFLAGS} -o libpgosm.so maptile-pgsql.o

quadtile.o: quadtile.c ${QTDIR}/quad_tile.h
	cc `mysql_config --include` -I${QTDIR} -fPIC -O3 -c -o quadtile.o quadtile.c

maptile-mysql.o: maptile.c
	cc `mysql_config --include` -fPIC -O3 -DUSE_MYSQL -c -o maptile-mysql.o maptile.c

maptile-pgsql.o: maptile.c
	cc -I${PGSQLINC} -O3 -fPIC -DUSE_PGSQL -c -o maptile-pgsql.o maptile.c