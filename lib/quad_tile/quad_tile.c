#include "ruby.h"
#include "quad_tile.h"

typedef struct {
   unsigned int *tilev;
   unsigned int tilec;
} tilelist_t;

static tilelist_t tilelist_for_area(unsigned int minx, unsigned int miny, unsigned int maxx, unsigned int maxy)
{
   unsigned int x;
   unsigned int y;
   tilelist_t   tl;
   unsigned int maxtilec;

   maxtilec = 256;

   tl.tilev = malloc(maxtilec * sizeof(unsigned int));
   tl.tilec = 0;

   for (x = minx; x <= maxx; x++)
   {
      for (y = miny; y <= maxy; y++)
      {
         if (tl.tilec == maxtilec)
         {
            maxtilec = maxtilec * 2;

            tl.tilev = realloc(tl.tilev, maxtilec * sizeof(unsigned int));
         }

         tl.tilev[tl.tilec++] = xy2tile(x, y);
      }
   }

   return tl;
}

static int tile_compare(const void *ap, const void *bp)
{
   unsigned int a = *(unsigned int *)ap;
   unsigned int b = *(unsigned int *)bp;

   if (a < b)
   {
      return -1;
   }
   else if (a > b)
   {
      return 1;
   }
   else
   {
      return 0;
   }
}

static VALUE tile_for_point(VALUE self, VALUE lat, VALUE lon)
{
   unsigned int x = lon2x(NUM2DBL(lon));
   unsigned int y = lat2y(NUM2DBL(lat));

   return UINT2NUM(xy2tile(x, y));
}

static VALUE tiles_for_area(VALUE self, VALUE bbox)
{
   unsigned int minx = lon2x(NUM2DBL(rb_iv_get(bbox, "@min_lon")));
   unsigned int maxx = lon2x(NUM2DBL(rb_iv_get(bbox, "@max_lon")));
   unsigned int miny = lat2y(NUM2DBL(rb_iv_get(bbox, "@min_lat")));
   unsigned int maxy = lat2y(NUM2DBL(rb_iv_get(bbox, "@max_lat")));
   tilelist_t   tl = tilelist_for_area(minx, miny, maxx, maxy);
   VALUE        tiles = rb_ary_new();
   unsigned int t;

   for (t = 0; t < tl.tilec; t++)
   {
      rb_ary_push(tiles, UINT2NUM(tl.tilev[t]));
   }

   free(tl.tilev);

   return tiles;
}

static VALUE tile_for_xy(VALUE self, VALUE x, VALUE y)
{
   return UINT2NUM(xy2tile(NUM2UINT(x), NUM2UINT(y)));
}

static VALUE iterate_tiles_for_area(VALUE self, VALUE bbox)
{
   unsigned int minx = lon2x(NUM2DBL(rb_iv_get(bbox, "@min_lon")));
   unsigned int maxx = lon2x(NUM2DBL(rb_iv_get(bbox, "@max_lon")));
   unsigned int miny = lat2y(NUM2DBL(rb_iv_get(bbox, "@min_lat")));
   unsigned int maxy = lat2y(NUM2DBL(rb_iv_get(bbox, "@max_lat")));
   tilelist_t   tl = tilelist_for_area(minx, miny, maxx, maxy);

   if (tl.tilec > 0)
   {
      unsigned int first;
      unsigned int last;
      unsigned int t;
      VALUE        a = rb_ary_new();

      qsort(tl.tilev, tl.tilec, sizeof(unsigned int), tile_compare);

      first = last = tl.tilev[0];

      for (t = 1; t < tl.tilec; t++)
      {
         unsigned int tile = tl.tilev[t];

         if (tile == last + 1)
         {
            last = tile;
         }
         else
         {
            rb_ary_store(a, 0, UINT2NUM(first));
            rb_ary_store(a, 1, UINT2NUM(last));
            rb_yield(a);

            first = last = tile;
         }
      }

      rb_ary_store(a, 0, UINT2NUM(first));
      rb_ary_store(a, 1, UINT2NUM(last));
      rb_yield(a);
   }

   free(tl.tilev);

   return Qnil;
}

void Init_quad_tile_so(void)
{
   VALUE m = rb_define_module("QuadTile");

   rb_define_module_function(m, "tile_for_point", tile_for_point, 2);
   rb_define_module_function(m, "tiles_for_area", tiles_for_area, 1);
   rb_define_module_function(m, "tile_for_xy", tile_for_xy, 2);
   rb_define_module_function(m, "iterate_tiles_for_area", iterate_tiles_for_area, 1);

   return;
}
