#include <math.h>
#include <quad_tile.h>
#include <postgres.h>
#include <fmgr.h>

Datum
tile_for_point(PG_FUNCTION_ARGS)
{
  double lat = PG_GETARG_INT32(0) / 10000000.0;
  double lon = PG_GETARG_INT32(1) / 10000000.0;

  PG_RETURN_INT64(xy2tile(lon2x(lon), lat2y(lat)));
}

PG_FUNCTION_INFO_V1(tile_for_point);

/*
 * To bind this into PGSQL, try something like:
 *
 * CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8
 *  AS '/path/to/rails-port/db/functions/libpgosm', 'tile_for_point'
 *  LANGUAGE C STRICT;
 *
 * (without all the *s)
 */
