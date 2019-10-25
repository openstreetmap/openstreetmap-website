--------------------------------------------------------------------------------
-- SQL versions of the C database functions.
--
-- Pure pl/pgsql versions are *slower* than the C versions, and not recommended
-- for production use. However, they are significantly easier to install, and
-- require fewer dependencies.
--------------------------------------------------------------------------------

-- tile_for_point function returns a Morton-encoded integer representing a z16
-- tile which contains the given (scaled_lon, scaled_lat) coordinate. Note that
-- these are passed into the function as (lat, lon) and should be scaled by
-- 10^7.
--
-- The Morton encoding packs two dimensions down to one with fairly good
-- spatial locality, and can be used to index points without the need for a
-- proper 2D index.
CREATE OR REPLACE FUNCTION tile_for_point(scaled_lat int4, scaled_lon int4)
  RETURNS int8
  AS $$
DECLARE
  x int8; -- quantized x from lon,
  y int8; -- quantized y from lat,
BEGIN
  x := round(((scaled_lon / 10000000.0) + 180.0) * 65535.0 / 360.0);
  y := round(((scaled_lat / 10000000.0) +  90.0) * 65535.0 / 180.0);

  -- these bit-masks are special numbers used in the bit interleaving algorithm.
  -- see https://graphics.stanford.edu/~seander/bithacks.html#InterleaveBMN
  -- for the original algorithm and more details.
  x := (x | (x << 8)) &   16711935; -- 0x00FF00FF
  x := (x | (x << 4)) &  252645135; -- 0x0F0F0F0F
  x := (x | (x << 2)) &  858993459; -- 0x33333333
  x := (x | (x << 1)) & 1431655765; -- 0x55555555

  y := (y | (y << 8)) &   16711935; -- 0x00FF00FF
  y := (y | (y << 4)) &  252645135; -- 0x0F0F0F0F
  y := (y | (y << 2)) &  858993459; -- 0x33333333
  y := (y | (y << 1)) & 1431655765; -- 0x55555555

  RETURN (x << 1) | y;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- maptile_for_point returns an integer representing the tile at the given zoom
-- which contains the point (scaled_lon, scaled_lat). Note that the arguments
-- are in the order (lat, lon), and should be scaled by 10^7.
--
-- The maptile_for_point function is used only for grouping the results of the
-- (deprecated?) /changes API call. Please don't use it for anything else, as
-- it might go away in the future.
CREATE OR REPLACE FUNCTION maptile_for_point(scaled_lat int8, scaled_lon int8, zoom int4)
  RETURNS int4
  AS $$
DECLARE
  lat CONSTANT DOUBLE PRECISION := scaled_lat / 10000000.0;
  lon CONSTANT DOUBLE PRECISION := scaled_lon / 10000000.0;
  zscale CONSTANT DOUBLE PRECISION := 2.0 ^ zoom;
  pi CONSTANT DOUBLE PRECISION := 3.141592653589793;
  r_per_d CONSTANT DOUBLE PRECISION := pi / 180.0;
  x int4;
  y int4;
BEGIN
  -- straight port of the C code. see db/functions/maptile.c
  x := floor((lon + 180.0) * zscale / 360.0);
  y := floor((1.0 - ln(tan(lat * r_per_d) + 1.0 / cos(lat * r_per_d)) / pi) * zscale / 2.0);

  RETURN (x << zoom) | y;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- xid_to_int4 converts a PostgreSQL transaction ID (xid) to a 32-bit integer
-- which can then be used to efficiently find rows which have changed between
-- two given transactions. This is currently used by Osmosis to extract a
-- stream of edits for "diff replication" **HOWEVER** this is a pain point, as
-- (ab)using the xid in this way is _not_ supported or recommended by Postgres
-- devs. It is preventing us upgrading to PostgreSQL version 10+, and will
-- hopefully be replaced Real Soon Now.
--
-- From the Osmosis distribution by Brett Henderson:
-- https://github.com/openstreetmap/osmosis/blob/master/package/script/contrib/apidb_0.6_osmosis_xid_indexing.sql
CREATE OR REPLACE FUNCTION xid_to_int4(t xid)
  RETURNS integer
  AS
$$
DECLARE
  tl bigint;
  ti int;
BEGIN
  tl := t;

  IF tl >= 2147483648 THEN
    tl := tl - 4294967296;
  END IF;

  ti := tl;

  RETURN ti;
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT;
