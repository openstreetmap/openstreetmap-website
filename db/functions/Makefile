PG_CONFIG ?= pg_config
DESTDIR ?= .

QTDIR=$(shell bundle show quad_tile)/ext/quad_tile

OS=$(shell uname -s)
ifeq (${OS},Darwin)
    LDFLAGS=-bundle
else
    LDFLAGS=-shared
endif

all: ${DESTDIR}/libpgosm.so

clean:
	$(RM) ${DESTDIR}/*.so ${DESTDIR}/*.o

${DESTDIR}/libpgosm.so: ${DESTDIR}/quadtile.o ${DESTDIR}/maptile.o ${DESTDIR}/xid_to_int4.o
	cc ${LDFLAGS} -o $@ $^

${DESTDIR}/%.o: %.c
	cc -I `${PG_CONFIG} --includedir` -I `${PG_CONFIG} --includedir-server` -I${QTDIR} -fPIC -O3 -DUSE_PGSQL -c -o $@ $<

${DESTDIR}/quadtile.o: ${QTDIR}/quad_tile.h
