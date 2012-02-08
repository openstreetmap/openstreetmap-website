#include <math.h>
#include <postgres.h>
#include <fmgr.h>

Datum
maptile_for_point(PG_FUNCTION_ARGS)
{
   double lat = PG_GETARG_INT64(0) / 10000000.0;
   double lon = PG_GETARG_INT64(1) / 10000000.0;
   int zoom = PG_GETARG_INT32(2);
   double scale = pow(2, zoom);
   double r_per_d = M_PI / 180;
   unsigned int x;
   unsigned int y;

   x = floor((lon + 180.0) * scale / 360.0);
   y = floor((1 - log(tan(lat * r_per_d) + 1.0 / cos(lat * r_per_d)) / M_PI) * scale / 2.0);

   PG_RETURN_INT32((x << zoom) | y);
}

PG_FUNCTION_INFO_V1(maptile_for_point);

/*
 * To bind this into PGSQL, try something like:
 *
 * CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4
 *  AS '/path/to/rails-port/db/functions/libpgosm', 'maptile_for_point'
 *  LANGUAGE C STRICT;
 *
 * (without all the *s)
 */

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif
