#include "ruby.h"
#include "quad_tile.h"

static VALUE tile_for_point(VALUE self, VALUE lat, VALUE lon)
{
   unsigned int x = lon2x(NUM2DBL(lon));
   unsigned int y = lat2y(NUM2DBL(lat));

   return UINT2NUM(xy2tile(x, y));
}

static VALUE tiles_for_area(VALUE self, VALUE minlat, VALUE minlon, VALUE maxlat, VALUE maxlon)
{
   unsigned int minx = lon2x(NUM2DBL(minlon));
   unsigned int maxx = lon2x(NUM2DBL(maxlon));
   unsigned int miny = lat2y(NUM2DBL(minlat));
   unsigned int maxy = lat2y(NUM2DBL(maxlat));
   VALUE        tiles = rb_ary_new();
   unsigned int x;
   unsigned int y;

   for (x = minx; x <= maxx; x++)
   {
      for (y = miny; y <= maxy; y++)
      {
         rb_ary_push(tiles, UINT2NUM(xy2tile(x, y)));
      }
   }

   return tiles;
}

static VALUE tile_for_xy(VALUE self, VALUE x, VALUE y)
{
   return UINT2NUM(xy2tile(NUM2UINT(x), NUM2UINT(y)));
}

void Init_quad_tile_so(void)
{
   VALUE m = rb_define_module("QuadTile");

   rb_define_module_function(m, "tile_for_point", tile_for_point, 2);
   rb_define_module_function(m, "tiles_for_area", tiles_for_area, 4);
   rb_define_module_function(m, "tile_for_xy", tile_for_xy, 2);

   return;
}
