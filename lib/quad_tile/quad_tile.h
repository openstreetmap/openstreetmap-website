#include <math.h>

static inline unsigned int xy2tile(unsigned int x, unsigned int y)
{
   unsigned int tile = 0;
   int          i;

   for (i = 15; i >= 0; i--)
   {
      tile = (tile << 1) | ((x >> i) & 1);
      tile = (tile << 1) | ((y >> i) & 1);
   }

   return tile;
}

static inline unsigned int lon2x(double lon)
{
   return round((lon + 180.0) * 65535.0 / 360.0);
}

static inline unsigned int lat2y(double lat)
{
   return round((lat + 90.0) * 65535.0 / 180.0);
}
