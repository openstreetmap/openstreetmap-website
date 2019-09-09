#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -c "CREATE EXTENSION btree_gist" openstreetmap
make -C db/functions libpgosm.so
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -c "CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT" openstreetmap
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -c "CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT" openstreetmap
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -c "CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT" openstreetmap
