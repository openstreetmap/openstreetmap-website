#include <my_global.h>
#include <my_sys.h>
#include <m_string.h>
#include <mysql.h>
#include <quad_tile.h>

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

   return xy2tile(lon2x(lon / 1000000.0), lat2y(lat / 1000000.0));
}
