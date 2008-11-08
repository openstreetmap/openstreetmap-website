#ifndef USE_MYSQL
#ifndef USE_PGSQL
#error One of USE_MYSQL or USE_PGSQL must be defined
#endif
#endif

#include <math.h>

/* The real maptile-for-point functionality is here */

static long long internal_maptile_for_point(double lat, double lon, long long zoom)
{
   double       scale = pow(2, zoom);
   double       r_per_d = M_PI / 180;
   unsigned int x;
   unsigned int y;

   x = floor((lon + 180.0) * scale / 360.0);
   y = floor((1 - log(tan(lat * r_per_d) + 1.0 / cos(lat * r_per_d)) / M_PI) * scale / 2.0);

   return (x << zoom) | y;
}

#ifdef USE_MYSQL
#ifdef USE_PGSQL
#error ONLY one of USE_MYSQL and USE_PGSQL should be defined
#endif

#include <my_global.h>
#include <my_sys.h>
#include <m_string.h>
#include <mysql.h>

my_bool maptile_for_point_init(UDF_INIT *initid, UDF_ARGS *args, char *message)
{
   if ( args->arg_count != 3 ||
        args->arg_type[0] != INT_RESULT ||
        args->arg_type[1] != INT_RESULT ||
        args->arg_type[2] != INT_RESULT )
   {
      strcpy( message, "Your maptile_for_point arguments are bogus!" );
      return 1;
   }

   return 0;
}

void maptile_for_point_deinit(UDF_INIT *initid)
{
   return;
}

long long maptile_for_point(UDF_INIT *initid, UDF_ARGS *args, char *is_null, char *error)
{
   double       lat = *(long long *)args->args[0] / 10000000.0;
   double       lon = *(long long *)args->args[1] / 10000000.0;
   long long    zoom = *(long long *)args->args[2];
   
   return internal_maptile_for_point(lat, lon, zoom);
}
#endif

#ifdef USE_PGSQL
#include <postgres.h>
#include <fmgr.h>

Datum
maptile_for_point(PG_FUNCTION_ARGS)
{
  double lat = PG_GETARG_INT64(0) / 10000000.0;
  double lon = PG_GETARG_INT64(1) / 10000000.0;
  int zoom = PG_GETARG_INT32(2);
  
  PG_RETURN_INT32(internal_maptile_for_point(lat, lon, zoom));
}

PG_FUNCTION_INFO_V1(maptile_for_point);

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

#endif
