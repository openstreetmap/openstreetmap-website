#ifndef USE_MYSQL
#ifndef USE_PGSQL
#error One of USE_MYSQL or USE_PGSQL must be defined
#endif
#endif

#include <math.h>
#include <quad_tile.h>

#ifdef USE_MYSQL
#ifdef USE_PGSQL
#error ONLY one of USE_MYSQL and USE_PGSQL should be defined
#endif

#include <my_global.h>
#include <my_sys.h>
#include <m_string.h>
#include <mysql.h>

my_bool tile_for_point_init(UDF_INIT *initid, UDF_ARGS *args, char *message)
{
   if ( args->arg_count != 2 ||
        args->arg_type[0] != INT_RESULT ||
        args->arg_type[1] != INT_RESULT )
   {
      strcpy( message, "Your tile_for_point arguments are bogus!" );
      return 1;
   }

   return 0;
}

void tile_for_point_deinit(UDF_INIT *initid)
{
   return;
}

long long tile_for_point(UDF_INIT *initid, UDF_ARGS *args, char *is_null, char *error)
{
   long long lat = *(long long *)args->args[0];
   long long lon = *(long long *)args->args[1];

   return xy2tile(lon2x(lon / 10000000.0), lat2y(lat / 10000000.0));
}
#endif

#ifdef USE_PGSQL
#ifdef USE_MYSQL
#error ONLY one of USE_MYSQL and USE_PGSQL should be defined
#endif

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

#endif
